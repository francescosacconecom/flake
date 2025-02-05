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

  options.modules.quark = {
    enable = lib.mkOption {
      description = "Whether to enable Quark.";
      default = false;
      type = lib.types.bool;
    };
    root = lib.mkOption {
      description = "The root directory to statically host.";
      type = lib.types.uniq lib.types.path;
    };
  };

  config = lib.mkIf config.modules.quark.enable {
    users = {
      users = {
        quark = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "www";
          createHome = true;
          home = config.modules.quark.root;
        };
      };
      groups = {
        www = { };
      };
    };

    system.activationScripts.www_group_permissions = ''
      chmod --recursive g+rwx ${config.modules.quark.root}
    '';

    systemd.services.quark = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      script = ''
        ${pkgs.quark}/bin/quark \
          -p 80 \
          -h localhost \
          -u quark \
          -g www \
          -d ${config.modules.quark.root} \
          -i index.html
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
