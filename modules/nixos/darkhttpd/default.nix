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
      description = "For each file relative to the root, the file containing its content.";
      default = { };
      type = lib.types.attrsOf lib.types.path;
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
            |> builtins.mapAttrs (
              relativePath: file: ''
                ${pkgs.coreutils}/bin/ln \
                  --force \
                  --symbolic \
                  ${file} \
                  ${config.modules.darkhttpd.root}/${relativePath}

                ${pkgs.coreutils}/bin/chown \
                  --recursive \
                  darkhttpd:www \
                  ${config.modules.darkhttpd.root}/${relativePath}
              ''
            )
            |> builtins.attrValues
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
                --ipv6 ${(if config.modules.darkhttpd.tls.enable then " --forward-https" else "")}
            ''
          ]
        )
        |> builtins.concatStringsSep "\n";
    };

    networking.firewall.allowedTCPPorts = [ 80 ];
  };
}
