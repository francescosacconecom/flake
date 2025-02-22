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
    programs.vim = {
      enable = true;
      packageConfigurable = pkgs.vim;

      defaultEditor = true;

      plugins = with pkgs.vimPlugins; [
        nerdtree
        editorconfig-vim
      ];

      extraConfig =
        [
          ./colorscheme.vim
          ./configuration.vim
        ]
        |> builtins.map builtins.readFile
        |> builtins.concatStringsSep "\n";
    };
  };
}
