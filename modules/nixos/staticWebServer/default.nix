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
        static-web-server-permissions = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Type = "oneshot";
          };
          script = ''
            ${pkgs.coreutils}/bin/chmod \
              --recursive \
              g+rwx \
              ${config.modules.staticWebServer.directory}
          '';
        };
        static-web-server-symlinks-clean = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "static-web-server";
            Group = "www";
            Type = "oneshot";
          };
          script = ''
            ${pkgs.coreutils}/bin/rm \
              --recursive \
              ${config.modules.staticWebServer.directory}/*
          '';
        };
        static-web-server-symlinks = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [ "static-web-server-symlinks-clean" ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Type = "oneshot";
          };
          script =
            config.modules.staticWebServer.symlinks
            |> builtins.mapAttrs (
              name: target: ''
                ${pkgs.coreutils}/bin/ln \
                  --force \
                  --symbolic \
                  ${target} \
                  ${config.modules.staticWebServer.directory}/${name}

                ${pkgs.coreutils}/bin/chown \
                  --recursive \
                  --no-dereference \
                  static-web-server:www \
                  ${config.modules.staticWebServer.directory}/${name}
              ''
            )
            |> builtins.attrValues
            |> builtins.concatStringsSep "\n";
        };
        static-web-server = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
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
        www-watcher = {
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
        www-watcher = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = config.modules.staticWebServer.directory;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
