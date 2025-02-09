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
        pandoc = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = "pandoc";
            Group = "pandoc";
            Type = "oneshot";
            ExecStart = let
              script = pkgs.writeShellScriptBin "pandoc" ''
                find "${config.modules.pandoc.input}" -name '*.md' | while read -r md_file; do
                  relative_path="$\{md_file#${config.modules.pandoc.input}/}"

                  output_file="${config.modules.pandoc.output}/$\{relative_path%.md}.html"
                  mkdir -p "$(dirname "$output_file")"

                  pandoc -f markdown -t html "$md_file" -o "$output_file"
                done
              '';
            in
              "${script}/bin/pandoc";
          };
        };
      };
    };
  };
}
