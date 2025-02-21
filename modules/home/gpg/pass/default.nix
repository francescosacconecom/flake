{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.gpg.pass = {
    enable = lib.mkOption {
      description = "Whether to enable Password Store.";
      default = false;
      type = lib.types.bool;
    };
    directory = lib.mkOption {
      description = "The directory containing the encrypted passwords.";
      default = "${config.home.homeDirectory}/.password-store";
      readOnly = true;
      type = lib.types.uniq lib.types.path;
    };
    passwords = lib.mkOption {
      description = "For each password name, its unarmored GPG file.";
      default = { };
      type = lib.types.attrsOf lib.types.path;
    };
  };

  config =
    let
      inherit (config.modules.gpg) pass;
    in
    lib.mkIf (config.modules.gpg.enable && pass.enable) {
      programs.password-store = {
        enable = true;
        package = pkgs.pass.withExtensions (exts: [
          exts.pass-otp
        ]);
        settings = {
          PASSWORD_STORE_DIR = pass.directory;
        };
      };

      home.file =
        {
          ".password-store/.gpg-id" = {
            text = config.modules.gpg.primaryKey.fingerprint;
          };
        }
        // (
          pass.passwords
          |> builtins.mapAttrs (
            name: file: {
              name = ".password-store/${name}.gpg";
              value = {
                source = file;
              };
            }
          )
          |> builtins.attrValues
          |> builtins.listToAttrs
        );

      home.packages = [ pkgs.wl-clipboard-rs ];
    };
}
