{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.staticWebServer.tls = {
    enable = lib.mkOption {
      description = "Whether to enable the Hitch reverse proxy.";
      default = false;
      type = lib.types.bool;
    };
    pemFiles = lib.mkOption {
      description = "The list of PEM files to pass to Hitch.";
      type = lib.types.listOf lib.types.path;
    };
  };

  config =
    lib.mkIf (config.modules.staticWebServer.tls.enable && config.modules.staticWebServer.enable)
      {
        users = {
          users = {
            hitch = {
              hashedPassword = "!";
              isSystemUser = true;
              group = "www";
              createHome = true;
              home = "/var/lib/hitch";
            };
          };
        };

        systemd.services.hitch = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [
            "static-web-server.service"
            "acme.service"
          ];
          serviceConfig = {
            User = "root";
            Group = "root";
          };
          script = ''
            ${pkgs.coreutils}/bin/cat \
            ${builtins.concatStringsSep " " config.modules.staticWebServer.tls.pemFiles} \
              > /var/lib/hitch/full.pem

            ${pkgs.hitch}/bin/hitch \
              --backend [localhost]:80 \
              --frontend [*]:443 \
              --backend-connect-timeout 30 \
              --ssl-handshake-timeout 30 \
              --ocsp-dir /var/lib/hitch \
              --user hitch \
              --group www \
              /var/lib/hitch/full.pem
          '';
        };

        networking.firewall.allowedTCPPorts = [ 443 ];
      };
}
