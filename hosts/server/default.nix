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
      records =
        let
          ttl = 3600;
        in
        [
          {
            name = "@";
            inherit ttl;
            class = "IN";
            type = "SOA";
            data = "ns1.${networking.domain}. admin.${networking.domain}. 2021090101 900 900 2592000 900";
          }
          {
            name = "@";
            inherit ttl;
            class = "IN";
            type = "NS";
            data = "ns1.${networking.domain}.";
          }
          {
            name = "ns1";
            inherit ttl;
            class = "IN";
            type = "A";
            data = "193.108.52.52";
          }
          {
            name = "ns1";
            inherit ttl;
            class = "IN";
            type = "AAAA";
            data = "2001:1600:13:101::16e3";
          }
          {
            name = "@";
            inherit ttl;
            class = "IN";
            type = "A";
            data = "193.108.52.52";
          }
          {
            name = "@";
            inherit ttl;
            class = "IN";
            type = "AAAA";
            data = "2001:1600:13:101::16e3";
          }
          {
            name = "@";
            inherit ttl;
            class = "IN";
            type = "MX";
            data = "10 ${modules.mailserver.hostDomain}.";
          }
          {
            name = "@";
            inherit ttl;
            class = "IN";
            type = "TXT";
            data = "\"v=spf1 mx -all\"";
          }
        ];
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
