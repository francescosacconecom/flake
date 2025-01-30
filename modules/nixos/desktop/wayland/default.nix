{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.desktop.wayland = {
    enable = lib.mkOption {
      description = "Whether to enable Ly and Sway, effectively enabling Wayland.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.desktop.wayland.enable {
    services.displayManager = {
      defaultSession = "Sway";
      ly = {
        enable = true;
        package = pkgs.ly;
      };
    };

    programs.sway = {
      enable = true;
      package = pkgs.sway;
      extraPackages = [ ];
    };

    services.logind = {
      killUserProcesses = true;
      lidSwitch = "poweroff";
      powerKey = "poweroff";
      powerKeyLongPress = "poweroff";
    };
  };
}
