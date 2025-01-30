{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.mediaViewers = {
    enable = lib.mkOption {
      description = "Whether to enable basic media viewers.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.mediaViewers.enable {
    programs.imv = {
      enable = true;
      package = pkgs.imv;
    };

    programs.mpv = {
      enable = true;
      package = pkgs.mpv-unwrapped;
    };
  };
}
