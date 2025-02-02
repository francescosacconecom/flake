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

  config = lib.mkIf config.modules.darkhttpd.tls.enable {
    users = {
      users = {
        hitch = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "hitch";
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
      after = [ "darkhttpd.service" ];
      script = ''
        ${pkgs.hitch}/bin/hitch \
          --backend localhost:80 \
          --frontend [*]:443 \
          --backend-connect-timeout 30 \
          --ssl-handshake-timeout 30 \
          --user $(${pkgs.coreutils}/bin/id -u hitch) \
          --group $(${pkgs.coreutils}/bin/id -g hitch) \
          ${builtins.concatStringsSep " " config.modules.darkhttpd.tls.pemFiles}
      '';
    };

    networking.firewall.allowedTCPPorts = [ 443 ];
  };
}
