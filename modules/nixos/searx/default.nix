{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.searx = {
    enable = lib.mkOption {
      description = "Whether to enable Searx.";
      default = false;
      type = lib.types.bool;
    };
    port = lib.mkOption {
      description = "The local port that Searx is hosted in.";
      default = 8888;
      type = lib.types.uniq lib.types.int;
    };
    secretKey = lib.mkOption {
      description = "The secret key used by Searx.";
      type = lib.types.uniq lib.types.str;
    };
  };

  config = lib.mkIf config.modules.searx.enable {
    services.searx = {
      enable = true;

      settings.server = {
        bind_address = "localhost";
        inherit (config.modules.searx) port;
        secret_key = config.modules.searx.secretKey;
      };
    };
  };
}
