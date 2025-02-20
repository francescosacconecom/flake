{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./pass
  ];

  options.modules.gpg = {
    enable = lib.mkOption {
      description = "Whether to enable GnuPG.";
      default = false;
      type = lib.types.bool;
    };
    primaryKey = {
      fingerprint = lib.mkOption {
        description = "The fingerprint of the primary key.";
        type = lib.types.uniq lib.types.str;
      };
      file = lib.mkOption {
        description = "The path to the primary key file.";
        type = lib.types.uniq lib.types.path;
      };
    };
  };

  config = lib.mkIf config.modules.gpg.enable {
    programs.gpg = {
      enable = true;
      package = pkgs.gnupg;

      mutableKeys = false;
      mutableTrust = false;

      publicKeys = [
        {
          source = config.modules.gpg.primaryKey.file;
          trust = "ultimate";
        }
      ];
    };

    services.gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-tty;
      extraConfig = ''
        allow-loopback-pinentry
      '';
    };
  };
}
