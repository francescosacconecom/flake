{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.system.sudo = {
    enable = lib.mkOption {
      description = "Whether to enable the sudo command.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.system.sudo.enable {
    security.sudo = {
      enable = true;
      package = pkgs.sudo;

      execWheelOnly = true;
      wheelNeedsPassword = true;
    };
  };
}
