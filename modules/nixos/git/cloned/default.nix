{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.git.cloned = {
    enable = lib.mkOption {
      description = "Whether to enable the service to clone and sync Git remote repositories.";
      default = false;
      type = lib.types.bool;
    };
    output = lib.mkOption {
      description = "The directory where cloned repositories will reside.";
      default = "/opt/git";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    repositories = lib.mkOption {
      description = "For each cloned repository name, its configuration.";
      default = [ ];
      type =
        lib.types.submodule {
          options = {
            url = lib.mkOption {
              description = "The URL to the remote repository.";
              type = lib.types.uniq lib.types.str;
            };
            branch = lib.mkOption {
              description = "The branch to checkout.";
              type = lib.types.uniq lib.types.str;
            };
          };
        }
        |> lib.types.attrsOf;
    };
  };

  config =
    let
      inherit (config.modules.git) cloned;
    in
    lib.mkIf (config.modules.git.enable && cloned.enable) {
      systemd = {
        services = {
          git-cloned-directory = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              User = "root";
              Group = "root";
              Type = "oneshot";
            };
            script = ''
              ${pkgs.coreutils}/bin/mkdir -p ${config.modules.git.cloned.output}
              ${pkgs.coreutils}/bin/chown -R git:git ${config.modules.git.cloned.output}
            '';
          };
          git-cloned = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "git-cloned-directory.service" ];
            serviceConfig = {
              User = "git";
              Group = "git";
              Type = "oneshot";
            };
            script =
              cloned.repositories
              |> builtins.mapAttrs (
                name:
                { url, branch }:
                ''
                  ${pkgs.coreutils}/bin/mkdir -p ${cloned.output}/${name}
                  ${pkgs.git}/bin/git clone ${url} ${cloned.output}/${name} || true
                  ${pkgs.git}/bin/git -C ${cloned.output}/${name} pull origin ${branch}
                  ${pkgs.git}/bin/git -C ${cloned.output}/${name} checkout ${branch}
                ''
              )
              |> builtins.attrValues
              |> builtins.concatStringsSep "\n";
          };
        };
        timers = {
          git-cloned = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            timerConfig = {
              OnBootSec = "15min";
              OnUnitActiveSec = "15min";
            };
          };
        };
      };
    };
}
