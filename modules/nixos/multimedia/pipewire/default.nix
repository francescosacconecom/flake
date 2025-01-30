{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.multimedia.pipewire = {
    enable = lib.mkOption {
      description = "Whether to enable PipeWire.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.multimedia.pipewire.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;

      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
