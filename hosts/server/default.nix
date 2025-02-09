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
          faviconPng = "${config.modules.git.stagit.output}/logo.png";
          logoPng = "${config.modules.git.stagit.output}/logo.png";
          styleCss = "${config.modules.git.stagit.output}/style.css";
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
    pandoc = {
      enable = true;
      input = "${config.modules.git.cloned.output}/website";
      components = {
        head = "${config.modules.git.cloned.output}/components/head.html";
        header = "${config.modules.git.cloned.output}/components/header.html";
        footer = "${config.modules.git.cloned.output}/components/footer.html";
      };
    };
    staticWebServer = rec {
      enable = true;
      symlinks = {
        git = config.modules.git.stagit.output;
        "index.html" = "${config.modules.pandoc.output}/index.html";
      };
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
