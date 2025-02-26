{
  lib,
  options,
  config,
  pkgs,
  inputs,
  ...
}:
{
  options.modules.vis = {
    enable = lib.mkOption {
      description = "Whether to enable Vis.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.vis.enable {
    home = {
      packages = [
        pkgs.vis
      ];
      sessionVariables = {
        EDITOR = "${pkgs.vis}/bin/vis";
      };
      file = {
        ".config/vis/visrc.lua".source = ./visrc.lua;
      };
    };
  };
}
