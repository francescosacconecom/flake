{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.monerod = {
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

  config = lib.mkIf config.modules.monerod.enable {
    services.monero = {
      enable = true;

      dataDir = "/var/lib/monero";
      mining =
        if config.modules.monerod.mining.enable then
          {
            enable = true;
            inherit (config.modules.monerod.mining) address;
            threads = 0;
          }
        else
          { };
    };
  };
}
