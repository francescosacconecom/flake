{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.git = {
    enable = lib.mkOption {
      description = "Whether to set up a Git server.";
      default = false;
      type = lib.types.bool;
    };
    repositories = lib.mkOption {
      description = "For each bare repository name, its configuration.";
      default = { };
      type =
        lib.types.submodule {
          options = {
            description = lib.mkOption {
              description = "The description.";
              type = lib.types.uniq lib.types.str;
            };
            owner = lib.mkOption {
              description = "The owner.";
              type = lib.types.uniq lib.types.str;
            };
          };
        }
        |> lib.types.attrsOf;
    };
    daemon = {
      enable = lib.mkOption {
        description = "Whether to enable Git daemon.";
        default = false;
        type = lib.types.bool;
      };
    };
  };

  config = lib.mkIf config.modules.git.enable {
    users = {
      users = {
        git = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "git";
          createHome = true;
          home = "/srv/git";
          shell = "${pkgs.git}/bin/git-shell";
        };
      };
      groups = {
        git = { };
      };
    };

    systemd.services = {
      git-repositories = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        script =
          config.modules.git.repositories
          |> builtins.mapAttrs (
            name:
            { description, owner }:
            ''
              ${pkgs.git}/bin/git \
                init \
                --quiet \
                --bare \
                --initial-branch master \
                /srv/git/${name}

              ${pkgs.coreutils}/bin/echo "${description}" > /srv/git/${name}/description

              ${pkgs.coreutils}/bin/echo "${owner}" > /srv/git/${name}/owner

              ${pkgs.coreutils}/bin/chown --recursive git:git /srv/git/${name}
            ''
          )
          |> builtins.attrValues
          |> builtins.concatStringsSep "\n";
      };
    };

    programs.git = {
      enable = true;
      package = pkgs.git;

      config = {
        init.defaultBranch = "master";
      };
    };

    services.gitDaemon = lib.mkIf config.modules.git.daemon.enable {
      enable = true;
      package = pkgs.git;

      user = "git";
      group = "git";
      basePath = "/srv/git";
      exportAll = true;

      port = 9418;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf config.modules.git.daemon.enable [
      9418
    ];
  };
}
