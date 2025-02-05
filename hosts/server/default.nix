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
      servedFiles = {
        "index.html" = pkgs.writeText "<h1>Working on this...</h1>";
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
    git = {
      enable = true;
      repositories = {
        flake = {
          inherit (inputs.self) description;
          owner = "Francesco Saccone <francesco@${networking.domain}>";
        };
      };
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
