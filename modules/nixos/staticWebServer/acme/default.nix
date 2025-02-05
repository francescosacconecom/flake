{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.staticWebServer.acme = {
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
  };

  config =
    lib.mkIf (config.modules.staticWebServer.acme.enable && config.modules.staticWebServer.enable)
      {
        security.acme = {
          acceptTerms = true;
          certs =
            let
              inherit (config.modules.staticWebServer) acme;
            in
            {
              ${acme.domain} = {
                inherit (acme) email domain;

                group = "www";
                webroot = config.modules.staticWebServer.root;
              };
            };
        };
      };
}
