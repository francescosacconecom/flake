{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    chromium = {
      enable = true;
    };
    monerod = {
      enable = true;
      mining = {
        enable = true;
        address = "44UAWDBRoxtXodXboy6LKEjokehoSiHwmNhgSYEvqzbiTmUnvMcNccFNsaAp7GCbDKhu62oeiEuj9HsPtwJi1p9V26ShoDh";
      };
    };
    wayland = {
      enable = true;
    };
    pipewire = {
      enable = true;
    };
    networkmanager = {
      enable = true;
    };
    openssh.agent = {
      enable = true;
    };
    searx = {
      enable = true;
      port = 8888;
      secretKey = builtins.getEnv "SEARX_SECRET_KEY";
    };
    syncthing = {
      enable = true;
      root = "/var/lib/syncthing";
      announce = {
        enable = true;
      };
      folders =
        let
          devices = [
            "AXH5A4N-C5MEHNR-AKFFXUO-CRNLEFI-XAGJ23U-25MIBSG-2WHJMZO-K35GHQF"
          ];
        in
        {
          music = {
            inherit devices;
          };
          notes = {
            inherit devices;
          };
          pictures = {
            inherit devices;
          };
          vault = {
            inherit devices;
          };
        };
    };
    sudo = {
      enable = true;
    };
    tlp = {
      enable = true;
    };
  };

  boot.loader = {
    timeout = 1;
    systemd-boot = {
      enable = true;
      editor = false;
    };
  };

  i18n.defaultLocale = "en_GB.UTF-8";
  time.timeZone = "Europe/Rome";

  security.pam.loginLimits = [
    {
      domain = "@realtime";
      type = "hard";
      item = "rtprio";
      value = 20;
    }
    {
      domain = "@realtime";
      type = "soft";
      item = "rtprio";
      value = 10;
    }
    {
      domain = "@audio";
      type = "-";
      item = "rtprio";
      value = 95;
    }
    {
      domain = "@audio";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];
}
