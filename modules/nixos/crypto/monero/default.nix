{
  lib,
  options,
  config,
  ...
}:
{
  options.modules.crypto.monero = {
    enable = lib.mkOption {
      description = "Whether to enable the Monero daemon.";
      default = false;
      type = lib.types.bool;
    };
    mining = {
      enable = lib.mkOption {
        description = "Whether to mine Monero.";
        default = false;
        type = lib.types.bool;
      };
      address = lib.mkOption {
        description = "The Monero address where rewards are sent.";
        type = lib.types.uniq lib.types.str;
      };
    };
  };

  config = lib.mkIf config.modules.crypto.monero.enable {
    services.monero = {
      enable = true;

      mining =
        if config.modules.crypto.monero.mining.enable then
          {
            enable = true;
            inherit (config.modules.crypto.monero.mining) address;
            threads = 0;
          }
        else
          { };
    };
  };
}
