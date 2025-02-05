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
    servedFiles = lib.mkOption {
      description = "The list of files or directories to be copied in the root directory.";
      default = [ ];
      type = lib.types.listOf lib.types.path;
    };
  };

  config = lib.mkIf config.modules.darkhttpd.enable {
    users = {
      users = {
        darkhttpd = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "www";
          createHome = true;
          home = config.modules.darkhttpd.root;
        };
      };
      groups = {
        www = { };
      };
    };

    system.activationScripts.www_group_permissions = ''
      chmod --recursive g+rwx ${config.modules.darkhttpd.root}
    '';

    systemd.services.darkhttpd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      script =
        (
          (
            config.modules.darkhttpd.servedFiles
            |> builtins.map (file: ''
              ${pkgs.coreutils}/bin/ln \
                --force \
                --symbolic \
                ${config.modules.darkhttpd.root}/${builtins.baseNameOf file} \
                ${file}
            '')
          )
          ++ [
            ''
              ${pkgs.darkhttpd}/bin/darkhttpd \
                ${config.modules.darkhttpd.root} \
                --port 80 \
                --chroot \
                --index index.html \
                --no-listing \
                --uid darkhttpd \
                --gid www \
                --no-server-id \
                --timeout 30 \
                --ipv6
            ''
          ]
        )
        |> builtins.concatStringsSep "\n";
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
