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
    darkhttpd = {
      enable = true;
      root = "/var/www";
      acme = {
        enable = true;
        email = "admin@${networking.domain}";
        inherit (networking) domain;
        output = {
          certificate = "/var/lib/acme/cert.pem";
          key = "/var/lib/acme/key.pem";
        };
      };
      tls = {
        enable = true;
        pemFile = [
          "/var/lib/acme/cert.pem"
          "/var/lib/acme/key.pem"
        ];
      };
    };
    git = {
      enable = true;
      daemon = {
        enable = true;
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
  };

  networking.domain = "francescosaccone.com";

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
}
