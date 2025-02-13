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
    components = {
      head = lib.mkOption {
        description = "The HTML <head> content.";
        default = pkgs.writeText "head.html" "";
        type = lib.types.uniq lib.types.path;
      };
      header = lib.mkOption {
        description = "The HTML <header> content.";
        default = pkgs.writeText "header.html" "";
        type = lib.types.uniq lib.types.path;
      };
      footer = lib.mkOption {
        description = "The HTML <footer> content.";
        default = pkgs.writeText "footer.html" "";
        type = lib.types.uniq lib.types.path;
      };
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
            ${pkgs.coreutils}/bin/rm -Rf ${config.modules.pandoc.output}/*
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
                inherit (config.modules.pandoc) input output components;
                script = pkgs.writeShellScriptBin "pandoc" ''
                  ${pkgs.findutils}/bin/find "${input}" -name '*.md' | while read -r md_file; do
                    relative_path="${"$"}{md_file#${input}/}"
                    output_file="${output}/${"$"}{relative_path%.md}.html"

                    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$output_file")"

                    ${pkgs.coreutils}/bin/echo "<!DOCTYPE html>"                       > "$output_file"
                    ${pkgs.coreutils}/bin/echo "<html>"                               >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "<head>"                               >> "$output_file"
                    ${pkgs.coreutils}/bin/cat "${components.head}"                    >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "</head>"                              >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "<body>"                               >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "<header>"                             >> "$output_file"
                    ${pkgs.coreutils}/bin/cat "${components.header}"                  >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "</header>"                            >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "<main>"                               >> "$output_file"
                    ${pkgs.pandoc}/bin/pandoc -f markdown -t html "$md_file" --mathml >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "</main>"                              >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "<footer>"                             >> "$output_file"
                    ${pkgs.coreutils}/bin/cat "${components.footer}"                  >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "</footer>"                            >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "</body>"                              >> "$output_file"
                    ${pkgs.coreutils}/bin/echo "</html>"                              >> "$output_file"
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
            OnCalendar = "*:0/1";
            Persistent = true;
          };
        };
      };
    };
  };
}
