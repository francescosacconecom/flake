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

  config = lib.mkIf (config.modules.darkhttpd.acme.enable && config.modules.darkhttpd.enable) {
    systemd = {
      services = {
        certbot = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          after = [ "darkhttpd.service" ];
          serviceConfig = {
            Type = "oneshot";
          };
          script = let
            inherit (config.modules.darkhttpd) acme;
          in pkgs.writeShellScriptBin "certbot-fetch" ''
            if [ ! -f /etc/letsencrypt/live/${acme.domain}/fullchain.pem ]; then
              ${pkgs.certbot}/bin/certbot \
                certonly \
                --non-interactive \
                --agree-tos \
                --email ${acme.email} \
                --key-type rsa \
                --rsa-key-size 4096 \
                --webroot \
                --webroot-path ${config.modules.darkhttpd.root} \
                --keep-until-expiring \
                --domain ${acme.domain}

              ${pkgs.coreutils}/bin/mkdir \
                --parents \
                ${builtins.dirOf acme.output.fullChain} \
                ${builtins.dirOf acme.output.privateKey}

              ${pkgs.coreutils}/bin/ln \
                --force \
                --symbolic \
                ${acme.output.fullChain} \
                /etc/letsencrypt/live/${acme.domain}/fullchain.pem

              ${pkgs.coreutils}/bin/ln \
                --force \
                --symbolic \
                ${acme.output.privateKey} \
                /etc/letsencrypt/live/${acme.domain}/privkey.pem
            fi
          '';
        };
        certbot-renewal = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          script = ''
            ${pkgs.certbot}/bin/certbot renew --non-interactive --quiet
          '';
        };
      };
      timers = {
        certbot-renewal = {
          enable = true;
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        };
      };
    };
  };
}
