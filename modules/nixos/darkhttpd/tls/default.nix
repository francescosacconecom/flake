{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.darkhttpd.tls = {
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

  config = lib.mkIf (config.modules.darkhttpd.tls.enable && config.modules.darkhttpd.enable) {
    users = {
      users = {
        hitch = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "hitch";
          extraGroups = [
            "acme"
          ];
          createHome = false;
        };
      };
      groups = {
        hitch = { };
      };
    };

    systemd.services.hitch = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [
        "darkhttpd.service"
      ] ++ (if config.modules.darkhttpd.acme.enable then [ "certbot.service" ] else [ ]);
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        ${pkgs.hitch}/bin/hitch \
          --backend [localhost]:80 \
          --frontend [localhost]:443 \
          --backend-connect-timeout 30 \
          --ssl-handshake-timeout 30 \
          --user hitch \
          --group hitch \
          ${builtins.concatStringsSep " " config.modules.darkhttpd.tls.pemFiles}
      '';
    };

    networking.firewall.allowedTCPPorts = [ 443 ];
  };
}
