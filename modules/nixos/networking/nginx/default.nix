{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.networking.nginx = {
    enable = lib.mkOption {
      description = "Whether to enable Nginx.";
      default = false;
      type = lib.types.bool;
    };
    hosts = lib.mkOption {
      description = "For each host domain, its configuration.";
      default = { };
      type =
        lib.types.submodule {
          options = {
            root = lib.mkOption {
              description = "The root directory to statically host.";
              type = lib.types.uniq lib.types.path;
            };
            ssl = {
              enable = lib.mkOption {
                description = "Whether to enable SSL/HTTPS";
                default = false;
                type = lib.types.bool;
              };
              acme = {
                email = lib.mkOption {
                  description = "The email used for CA account creation.";
                  type = lib.types.uniq lib.types.str;
                };
              };
            };
          };
        }
        |> lib.types.attrsOf;
    };
  };

  config = lib.mkIf config.modules.networking.nginx.enable {
    users.users.nginx.extraGroups = [ "acme" ];

    systemd.services =
      config.modules.networking.nginx.hosts
      |> builtins.attrValues
      |> builtins.map (hostConfig: {
        name = "${builtins.replaceStrings [ "/" ] [ "-" ] hostConfig.root}-nginx-chown";
        value = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          script = ''
            ${pkgs.coreutils}/bin/chown --recursive nginx:nginx ${hostConfig.root}
          '';
        };
      })
      |> builtins.listToAttrs;

    services.nginx = {
      enable = true;
      package = pkgs.nginxStable;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts =
        config.modules.networking.nginx.hosts
        |> builtins.mapAttrs (
          domain: hostConfig: {
            inherit (hostConfig) root;

            listen =
              [
                {
                  addr = domain;
                  port = 80;
                  ssl = false;
                }
              ]
              ++ (
                if hostConfig.ssl.enable then
                  [
                    {
                      addr = domain;
                      port = 443;
                      ssl = true;
                    }
                  ]
                else
                  [ ]
              );

            useACMEHost = if hostConfig.ssl.enable then domain else null;
            forceSSL = hostConfig.ssl.enable;
          }
        );
    };

    security.acme = {
      acceptTerms = true;
      certs =
        config.modules.networking.nginx.hosts
        |> builtins.mapAttrs (
          domain: hostConfig:
          if hostConfig.ssl.enable then
            {
              webroot = "/var/lib/acme/acme-challenge/${domain}";
              inherit (hostConfig.ssl.acme) email;
            }
          else
            {
            }
        );
    };

    networking.firewall.allowedTCPPorts =
      [ 80 ]
      ++ (
        if
          config.modules.networking.nginx.hosts |> builtins.attrValues |> builtins.any (host: host.ssl.enable)
        then
          [ 443 ]
        else
          [ ]
      );
  };
}
