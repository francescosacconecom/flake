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
            baseUrl = lib.mkOption {
              description = "The base URL used to clone the repository through the Git protocol.";
              type = lib.types.uniq lib.types.str;
            };
          };
        }
        |> lib.types.attrsOf;
    };
    stagit = {
      enable = lib.mkOption {
        description = "Whether to enable Stagit.";
        default = false;
        type = lib.types.bool;
      };
      output = lib.mkOption {
        description = "The directory where generated HTML files will reside.";
        type = lib.types.uniq lib.types.path;
      };
      baseUrl = lib.mkOption {
        description = "The base URL used to make links in the Atom feed generated by Stagit.";
        type = lib.types.uniq lib.types.str;
      };
      assets = {
        faviconPng = lib.mkOption {
          description = "The favicon.png file.";
          default = null;
          type = lib.types.nullOr lib.types.path;
        };
        logoPng = lib.mkOption {
          description = "The logo.png file.";
          default = null;
          type = lib.types.nullOr lib.types.path;
        };
        styleCss = lib.mkOption {
          description = "The style.png file.";
          default = null;
          type = lib.types.nullOr lib.types.path;
        };
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
          extraGroups = lib.mkIf config.modules.git.stagit.enable [ "www" ];
          createHome = true;
          home = "/srv/git";
          shell = "${pkgs.git}/bin/git-shell";
        };
      };
      groups = {
        git = { };
      };
    };

    systemd =  let
      inherit (config.modules.git) stagit;
    in {
      services = {
        git-repositories = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          script =
            config.modules.git.repositories
            |> builtins.mapAttrs (
              name:
              {
                description,
                owner,
                baseUrl,
              }:
              ''
                ${pkgs.git}/bin/git \
                  init \
                  --quiet \
                  --bare \
                  --initial-branch master \
                  /srv/git/${name}

                ${pkgs.coreutils}/bin/echo "${description}" > /srv/git/${name}/description

                ${pkgs.coreutils}/bin/echo "${owner}" > /srv/git/${name}/owner

                ${pkgs.coreutils}/bin/echo "git://${baseUrl}/${name}" > /srv/git/${name}/url

                ${pkgs.coreutils}/bin/chown --recursive git:git /srv/git/${name}
              ''
            )
            |> builtins.attrValues
            |> builtins.concatStringsSep "\n";
        };
        stagit = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          script = ''
            ${
              (
                config.modules.git.repositories
                |> builtins.attrNames
                |> builtins.map (name: ''
                  ${pkgs.coreutils}/bin/mkdir -p ${stagit.output}/${name}
                  cd ${stagit.output}/${name}

                  ${pkgs.stagit}/bin/stagit /srv/git/${name}

                  ${
                    (
                      if stagit.assets.faviconPng != null then
                        ''
                          ${pkgs.coreutils}/bin/ln \
                            --force \
                            --symbolic \
                            ${stagit.assets.faviconPng} \
                            ${stagit.output}/${name}/favicon.png
                        ''
                      else
                        ""
                    )
                  }

                  ${
                    (
                      if stagit.assets.logoPng != null then
                        ''
                          ${pkgs.coreutils}/bin/ln \
                            --force \
                            --symbolic \
                            ${stagit.assets.logoPng} \
                            ${stagit.output}/${name}/logo.png
                        ''
                      else
                        ""
                    )
                  }

                  ${
                    (
                      if stagit.assets.styleCss != null then
                        ''
                          ${pkgs.coreutils}/bin/ln \
                            --force \
                            --symbolic \
                            ${stagit.assets.styleCss} \
                            ${stagit.output}/${name}/style.css
                        ''
                      else
                        ""
                    )
                  }
                '')
              )
              |> builtins.concatStringsSep "\n"
            }

            ${pkgs.stagit}/bin/stagit-index ${
              (
                config.modules.git.repositories
                |> builtins.attrNames
                |> builtins.map (name: "/srv/git/${name}")
                |> builtins.concatStringsSep " "
              )
            } > ${stagit.output}/index.html

            ${
              (
                if stagit.assets.faviconPng != null then
                  ''
                    ${pkgs.coreutils}/bin/ln \
                      --force \
                      --symbolic \
                      ${stagit.assets.faviconPng} \
                      ${stagit.output}/favicon.png
                  ''
                else
                  ""
              )
            }

            ${
              (
                if stagit.assets.logoPng != null then
                  ''
                    ${pkgs.coreutils}/bin/ln \
                      --force \
                      --symbolic \
                      ${stagit.assets.logoPng} \
                      ${stagit.output}/logo.png
                  ''
                else
                  ""
              )
            }

            ${
              (
                if stagit.assets.styleCss != null then
                  ''
                    ${pkgs.coreutils}/bin/ln \
                      --force \
                      --symbolic \
                      ${stagit.assets.styleCss} \
                      ${stagit.output}/style.css
                  ''
                else
                  ""
              )
            }

            ${pkgs.coreutils}/bin/chown \
              --recursive \
              git:www \
              ${stagit.output}

            ${pkgs.coreutils}/bin/chmod \
              --recursive \
              g+r \
              ${stagit.output}
          '';
        };
        stagit-watcher = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
          };
          script = "${pkgs.systemdMinimal}/bin/systemctl restart stagit.service";
        };
      };
      paths = {
        stagit-watcher = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = "/srv/git";
          };
        };
      };
    };

    programs.git = {
      enable = true;
      package = pkgs.git;

      config = {
        init.defaultBranch = "master";
      };
    };

    services.gitDaemon = {
      enable = true;
      package = pkgs.git;

      user = "git";
      group = "git";
      basePath = "/srv/git";
      repositories =
        config.modules.git.repositories |> builtins.attrNames |> builtins.map (name: "/srv/git/${name}");

      port = 9418;
    };

    networking.firewall.allowedTCPPorts = [ 9418 ];
  };
}
