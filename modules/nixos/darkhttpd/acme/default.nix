{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.darkhttpd.acme = {
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
    output = {
      fullChain = lib.mkOption {
        description = "The symlink to the fetched fullchain.pem file.";
        type = lib.types.uniq lib.types.path;
      };
      privateKey = lib.mkOption {
        description = "The symlink to the fetched privkey.pem file.";
        type = lib.types.uniq lib.types.path;
      };
    };
  };

  config = lib.mkIf config.modules.darkhttpd.acme.enable {
    systemd.services.certbot = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "darkhttpd.service" ];
      script = ''
        ${pkgs.certbot}/bin/certbot \
          certonly \
          --non-interactive \
          --agree-tos \
          --email ${config.modules.darkhttpd.acme.email} \
          --key-type rsa \
          --rsa-key-size 4096 \
          --webroot \
          --webroot-path ${config.modules.darkhttpd.root} \
          --domain ${config.modules.darkhttpd.acme.domain}

        ${pkgs.coreutils}/bin/mkdir \
          --parents \
          ${builtins.dirOf config.modules.darkhttpd.acme.output.fullChain} \
          ${builtins.dirOf config.modules.darkhttpd.acme.output.privateKey}

        ${pkgs.coreutils}/bin/ln \
          --force \
          --symbolic \
          ${config.modules.darkhttpd.acme.output.fullChain} \
          /etc/letsencrypt/live/${config.modules.darkhttpd.acme.domain}/fullchain.pem

        ${pkgs.coreutils}/bin/ln \
          --force \
          --symbolic \
          ${config.modules.darkhttpd.acme.output.privateKey} \
          /etc/letsencrypt/live/${config.modules.darkhttpd.acme.domain}/privkey.pem
      '';
    };
  };
}
