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
    root = lib.mkOption {
      description = "The root directory to statically host.";
      type = lib.types.uniq lib.types.path;
    };
    symlinks = lib.mkOption {
      description = "The list of symlink configurations to be put in the root folder.";
      default = [ ];
      type =
        lib.types.submodule {
          options = {
            target = lib.mkOption {
              description = "The target file.";
              type = lib.types.uniq lib.types.path;
            };
            name = lib.mkOption {
              description = "The name of the symlink.";
              type = lib.types.uniq lib.types.str;
            };
          };
        }
        |> lib.types.listOf;
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
          home = config.modules.staticWebServer.root;
        };
      };
      groups = {
        www = { };
      };
    };

    system.activationScripts.wwwGroupPermissions = ''
      ${pkgs.coreutils}/bin/chmod --recursive g+rwx ${config.modules.staticWebServer.root}
    '';

    systemd = {
      services = {
        static-web-server-symlinks = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "root";
            Group = "root";
            Type = "oneshot";
          };
          script =
            config.modules.staticWebServer.symlinks
            |> builtins.map (
              { target, name }:
              ''
                ${pkgs.coreutils}/bin/ln \
                  --force \
                  --symbolic \
                  ${target} \
                  ${config.modules.staticWebServer.root}/${name}

                ${pkgs.coreutils}/bin/chown \
                  --recursive \
                  --no-dereference \
                  static-web-server:www \
                  ${config.modules.staticWebServer.root}/${name}
              ''
            )
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
              --root ${config.modules.staticWebServer.root} \
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
            PathModified = config.modules.staticWebServer.root;
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
