{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.quark.tls = {
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

  config = lib.mkIf (config.modules.quark.tls.enable && config.modules.quark.enable) {
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
        "quark.service"
      ] ++ (if config.modules.quark.acme.enable then [ "certbot.service" ] else [ ]);
      script = ''
        ${pkgs.hitch}/bin/hitch \
          --backend [localhost]:80 \
          --frontend [*]:443 \
          --backend-connect-timeout 30 \
          --ssl-handshake-timeout 30 \
          --ocsp-dir /var/lib/hitch \
          --user hitch \
          --group www \
          ${builtins.concatStringsSep " " config.modules.quark.tls.pemFiles}
      '';
    };

    networking.firewall.allowedTCPPorts = [ 443 ];
  };
}
