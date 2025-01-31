{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./disk-config.nix
  ];

  modules = {
    networking = rec {
      bind = rec {
        enable = true;
        domain = "francescosaccone.com";
        records =
          let
            ttl = 3600;
          in
          [
            # SOA
            {
              name = "@";
              inherit ttl;
              class = "IN";
              type = "SOA";
              data = "ns1.${domain}. admin.${domain}. 2021090101 900 900 2592000 900";
            }

            # Nameserver 1
            {
              name = "@";
              inherit ttl;
              class = "IN";
              type = "NS";
              data = "ns1.${domain}.";
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

            # Apex
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

            # Git
            {
              name = "git";
              inherit ttl;
              class = "IN";
              type = "A";
              data = "193.108.52.52";
            }
            {
              name = "git";
              inherit ttl;
              class = "IN";
              type = "AAAA";
              data = "2001:1600:13:101::16e3";
            }

            # Notes
            {
              name = "notes";
              inherit ttl;
              class = "IN";
              type = "A";
              data = "193.108.52.52";
            }
            {
              name = "notes";
              inherit ttl;
              class = "IN";
              type = "AAAA";
              data = "2001:1600:13:101::16e3";
            }

            # Music
            {
              name = "music";
              inherit ttl;
              class = "IN";
              type = "A";
              data = "193.108.52.52";
            }
            {
              name = "music";
              inherit ttl;
              class = "IN";
              type = "AAAA";
              data = "2001:1600:13:101::16e3";
            }

            # Email
            {
              name = "mx";
              inherit ttl;
              class = "IN";
              type = "A";
              data = "193.108.52.52";
            }
            {
              name = "mx";
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
              data = "10 mx.${domain}.";
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
        stagit = rec {
          enable = true;
          root = "/var/www/git";
          logoPng = ./website/logo.png;
          faviconPng = logoPng;
        };
      };
      mailserver = {
        enable = true;
        addressDomain = bind.domain;
        hostDomain = "mx.${bind.domain}";
        acme = {
          email = "admin@${bind.domain}";
        };
        accounts = {
          "francesco" = {
            hashedPassword = "$y$j9T$fM7MqDwT1ViKNurSFijqN0$XoRyKBUzsMt4oigUcWkDQf7cU6JYz5A61wZlQrlannD";
            aliasNames = [ "admin" ];
          };
        };
      };
      nginx = {
        enable = true;
        hosts = {
          "git.${bind.domain}" = {
            root = "/var/www/git";
            ssl = {
              enable = true;
              acme = {
                email = "admin@${bind.domain}";
              };
            };
          };
          "music.${bind.domain}" = {
            root = "/var/lib/syncthing/music";
            ssl = {
              enable = true;
              acme = {
                email = "admin@${bind.domain}";
              };
            };
          };
          "notes.${bind.domain}" = {
            root = "/var/lib/syncthing/notes";
            ssl = {
              enable = true;
              acme = {
                email = "admin@${bind.domain}";
              };
            };
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
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
