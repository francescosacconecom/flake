{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.networkmanager = {
    enable = lib.mkOption {
      description = "Whether to enable NetworkManager.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.networkmanager.enable {
    networking.networkmanager = {
      enable = true;
    };
  };
}
