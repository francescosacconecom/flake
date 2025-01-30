{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.system.tlp = {
    enable = lib.mkOption {
      description = "Whether to enable TLP.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.system.tlp.enable {
    services.tlp = {
      enable = true;
    };
  };
}
