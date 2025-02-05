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
    darkhttpd = rec {
      enable = true;
      root = "/var/www";
      acme = {
        enable = true;
        email = "admin@${networking.domain}";
        inherit (networking) domain;
        extraDomains = [
          "*.${networking.domain}"
        ];
      };
      tls = {
        enable = true;
        pemFiles = [
          (acme.output + "/fullchain.pem")
          (acme.output + "/privkey.pem")
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
