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
