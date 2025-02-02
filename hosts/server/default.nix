{
  config,
  pkgs,
  ...
}:
rec {
  imports = [
    ./disk-config.nix
  ];

  modules = {
    bind = {
      enable = true;
      inherit (networking) domain;
      records = import ./dns.nix networking.domain;
    };
    git = {
      enable = true;
      daemon = {
        enable = true;
      };
    };
    mailserver = {
      enable = true;
      addressDomain = networking.domain;
      hostDomain = networking.domain;
      acmeEmail = "admin@${networking.domain}";
      accounts = {
        "francesco" = {
          hashedPassword = "$y$j9T$fM7MqDwT1ViKNurSFijqN0$XoRyKBUzsMt4oigUcWkDQf7cU6JYz5A61wZlQrlannD";
          aliasNames = [ "admin" ];
        };
      };
    };
    openssh.listen = {
      enable = true;
      port = 22;
      authorizedKeyFiles = rec {
        root = [
          ./ssh/francescoSaccone
        ];
        git = root;
      };
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
            "EWZK7V3-2LU7653-G25DOIA-KGGTSVR-GOHDYLU-F7EHMPQ-5P2OPUR-QIHBTAH"
          ];
        in
        {
          music = {
            inherit devices;
          };
          notes = {
            inherit devices;
          };
        };
    };
  };

  networking.domain = "francescosaccone.com";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
