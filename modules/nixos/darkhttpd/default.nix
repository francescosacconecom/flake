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

  options.modules.darkhttpd = {
    enable = lib.mkOption {
      description = "Whether to enable Darkhttpd.";
      default = false;
      type = lib.types.bool;
    };
    root = lib.mkOption {
      description = "The root directory to statically host.";
      type = lib.types.uniq lib.types.path;
    };
  };

  config = lib.mkIf config.modules.darkhttpd.enable {
    users = {
      users = {
        darkhttpd = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "darkhttpd";
          createHome = true;
          home = config.modules.darkhttpd.root;
        };
      };
      groups = {
        darkhttpd = { };
      };
    };

    systemd.services.darkhttpd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      script = ''
        ${pkgs.darkhttpd}/bin/darkhttpd \
          ${config.modules.darkhttpd.root} \
          --port 80 \
          --chroot \
          --index index.html \
          --no-listing \
          --uid darkhttpd \
          --gid darkhttpd \
          --no-server-id \
          --timeout 30 \
          --ipv6
      '';
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
