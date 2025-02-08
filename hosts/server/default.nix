{
  config,
  pkgs,
  inputs,
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
      repositories = {
        flake = {
          description = "Francesco Saccone's Nix flake.";
          owner = "Francesco Saccone";
          baseUrl = networking.domain;
        };
        website = {
          description = "Francesco Saccone's website content.";
          owner = "Francesco Saccone";
          baseUrl = networking.domain;
        };
      };
      cloned = {
        enable = true;
        repositories = {
          website = {
            url = "${config.modules.git.directory}/website";
            branch = "master";
          };
        };
      };
      daemon = {
        enable = true;
      };
      stagit = {
        enable = true;
        baseUrl = "https://${networking.domain}/git";
        assets = {
          faviconPng = ./website/logo.png;
          logoPng = ./website/logo.png;
          styleCss = ./website/style/git.css;
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
    staticWebServer = rec {
      enable = true;
      root = "/var/www";
      symlinks = [
        {
          target = config.modules.git.stagit.output;
          name = "git";
        }
      ];
      acme = {
        enable = true;
        email = "admin@${networking.domain}";
        inherit (networking) domain;
      };
      tls = {
        enable = true;
        pemFiles = [
          (config.security.acme.certs.${acme.domain}.directory + "/full.pem")
        ];
      };
    };
  };

  networking.domain = "francescosaccone.com";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
