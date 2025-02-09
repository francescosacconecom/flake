{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./acme
    ./tls
  ];

  options.modules.staticWebServer = {
    enable = lib.mkOption {
      description = "Whether to enable Static Web Server.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The root directory to statically host.";
      default = "/var/www";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    symlinks = lib.mkOption {
      description = "For each symlink name, which will be created in the root directory, its target.";
      default = { };
      type = lib.types.attrsOf lib.types.path;
    };
  };

  config = lib.mkIf config.modules.staticWebServer.enable {
    users = {
      users = {
        static-web-server = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "www";
          createHome = true;
          home = config.modules.staticWebServer.directory;
        };
      };
      groups = {
        www = { };
      };
    };

    systemd = {
      services = {
        static-web-server-directory = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          before = lib.mkIf config.modules.staticWebServer.acme.enable [
            "acme-${config.modules.staticWebServer.acme.domain}.service"
          ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Type = "oneshot";
          };
          script = ''
            ${pkgs.findutils}/bin/find ${config.modules.staticWebServer.directory} \
              -mindepth 1 -not -name '.well-known' -exec ${pkgs.coreutils}/bin/rm -Rf {} +
            ${pkgs.coreutils}/bin/chmod -R g+rwx ${config.modules.staticWebServer.directory}
          '';
        };
        static-web-server-symlinks = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          requires = [ "static-web-server-directory.service" ];
          after = [ "static-web-server-directory.service" ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Type = "oneshot";
          };
          script =
            config.modules.staticWebServer.symlinks
            |> builtins.mapAttrs (
              name: target: ''
                ${pkgs.coreutils}/bin/mkdir -p ${config.modules.staticWebServer.directory}/${builtins.dirOf name}
                ${pkgs.coreutils}/bin/ln -sf ${target} ${config.modules.staticWebServer.directory}/${name}
                ${pkgs.coreutils}/bin/chown -Rh static-web-server:www ${config.modules.staticWebServer.directory}
              ''
            )
            |> builtins.attrValues
            |> builtins.concatStringsSep "\n";
        };
        static-web-server = rec {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          requires =
            [
              "static-web-server-symlinks.service"
            ]
            ++ (
              if config.modules.staticWebServer.tls.enable then
                [
                  "hitch.service"
                ]
              else
                [ ]
            );
          after = [ "network.target" ];
          serviceConfig = {
            User = "root";
            Group = "root";
          };
          script = ''
            ${pkgs.static-web-server}/bin/static-web-server \
              --port 80 \
              --http2 false \
              --root ${config.modules.staticWebServer.directory} \
              --index-files index.html \
              --ignore-hidden-files false \
              ${if config.modules.staticWebServer.tls.enable then "--https-redirect" else ";"}
          '';
        };
        static-web-server-restarter = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            Type = "oneshot";
          };
          script = "${pkgs.systemdMinimal}/bin/systemctl restart static-web-server.service";
        };
      };
      paths = {
        static-web-server-restarter = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            pathModified = config.modules.staticWebServer.directory;
          };
        };
      };
      timers = {
        static-web-server-restarter = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          timerConfig = {
            OnCalendar = "*:0/1";
            Persistent = true;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
