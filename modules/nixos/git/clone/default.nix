{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.git.clone = {
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
      inherit (config.modules.git) clone;
    in
    lib.mkIf (config.modules.git.enable && clone.enable) {
      systemd = {
        services = {
          git-clone-directory = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              User = "root";
              Group = "root";
              Type = "oneshot";
            };
            script = ''
              ${pkgs.coreutils}/bin/mkdir -p ${config.modules.git.clone.output}
              ${pkgs.coreutils}/bin/chown -R git:git ${config.modules.git.clone.output}
            '';
          };
          git-clone = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "git-clone-directory.service" ];
            serviceConfig = {
              User = "git";
              Group = "git";
              Type = "oneshot";
            };
            script =
              clone.repositories
              |> builtins.mapAttrs (
                name:
                { url, branch }:
                ''
                  ${pkgs.coreutils}/bin/mkdir -p ${clone.output}/${name}
                  ${pkgs.git}/bin/git clone ${url} ${clone.output}/${name} || true
                  ${pkgs.git}/bin/git -C ${clone.output}/${name} pull origin ${branch}
                  ${pkgs.git}/bin/git -C ${clone.output}/${name} checkout ${branch}
                ''
              )
              |> builtins.attrValues
              |> builtins.concatStringsSep "\n";
          };
        };
        timers = {
          git-clone = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            timerConfig = {
              OnCalendar = "*:0/15";
              Persistent = true;
            };
          };
        };
      };
    };
}
