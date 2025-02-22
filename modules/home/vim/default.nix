{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.vim = {
    enable = lib.mkOption {
      description = "Whether to enable Vim.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.vim.enable {
    home = {
      packages = [
        pkgs.vim
      ];
      sessionVariables = {
        EDITOR = "${pkgs.vim}/bin/vim";
      };
      file = {
        ".vimrc".text =
          [
            ./colorscheme.vim
            ./configuration.vim
          ]
          |> builtins.map builtins.readFile
          |> builtins.concatStringsSep "\n";
      };
    };
  };
}
