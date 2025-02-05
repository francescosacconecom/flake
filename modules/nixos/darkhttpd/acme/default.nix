{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.darkhttpd.acme = rec {
    enable = lib.mkOption {
      description = "Whether to enable the Certbot ACME client.";
      default = false;
      type = lib.types.bool;
    };
    email = lib.mkOption {
      description = "The email used for the Let's Encrypt account.";
      type = lib.types.uniq lib.types.str;
    };
    domain = lib.mkOption {
      description = "The domain to fetch the certificate for.";
      type = lib.types.uniq lib.types.str;
    };
    extraDomains = lib.mkOption {
      description = "The domains to be included in the certificate.";
      type = lib.types.listOf lib.types.str;
    };
    output = lib.mkOption {
      description = "The directory where the .pem files will reside.";
      readOnly = true;
      default = security.acme.certs.${domain}.directory;
      type = lib.types.uniq lib.types.path;
    };
  };

  config = lib.mkIf (config.modules.darkhttpd.acme.enable && config.modules.darkhttpd.enable) {
    users = {
      groups = {
        acme = { };
      };
    };

    security.acme = {
      acceptTerms = true;
      certs =
        let
          inherit (config.modules.darkhttpd) acme;
        in
        {
          ${domain} = {
            inherit (acme) email domain;
            directory = acme.output;
            extraDomainNames = acme.extraDomains;

            group = "acme";
            webroot = config.modules.darkhttpd.root;
          };
        };
    };
  };
}
