{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.pandoc = {
    enable = lib.mkOption {
      description = "Whether to enable Pandoc to convert Markdown to HTML.";
      default = false;
      type = lib.types.bool;
    };
    output = lib.mkOption {
      description = "The directory where generated HTML files will reside.";
      default = "/opt/pandoc";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    input = lib.mkOption {
      description = "The directory containing the Markdown files.";
      type = lib.types.uniq lib.types.path;
    };
  };

  config = lib.mkIf config.modules.pandoc.enable {
    users = {
      users = {
        pandoc = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "pandoc";
          createHome = true;
          home = config.modules.pandoc.output;
        };
      };
      groups = {
        pandoc = { };
      };
    };

    systemd = {
      services = {
        pandoc-clean = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "pandoc";
            Group = "pandoc";
            Type = "oneshot";
          };
          script = ''
            ${pkgs.coreutils}/bin/rm \
              --recursive \
              --force \
              ${config.modules.pandoc.output}/*
          '';
        };
        pandoc = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [ "pandoc-clean.service" ];
          requires = [ "pandoc-clean.service" ];
          serviceConfig = {
            User = "pandoc";
            Group = "pandoc";
            Type = "oneshot";
            ExecStart =
              let
                inherit (config.modules.pandoc) input output;
                script = pkgs.writeShellScriptBin "pandoc" ''
                  ${pkgs.findutils}/bin/find "${input}" -name '*.md' | while read -r md_file; do
                    relative_path="${"$"}{md_file#${input}/}"
                    output_file="${output}/${"$"}{relative_path%.md}.html"

                    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$output_file")"
                    ${pkgs.pandoc}/bin/pandoc -f markdown -t html "$md_file" -o "$output_file"
                  done
                '';
              in
              "${script}/bin/pandoc";
          };
        };
      };
      timers = {
        pandoc = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          timerConfig = {
            OnActiveSec = "1min";
            OnUnitActiveSec = "1min";
          };
        };
      };
    };
  };
}
