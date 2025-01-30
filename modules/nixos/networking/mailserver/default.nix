{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.networking.mailserver = rec {
    enable = lib.mkOption {
      description = "Whether to enable NixOS Mailserver.";
      default = false;
      type = lib.types.bool;
    };
    addressDomain = lib.mkOption {
      description = "The domain used for the email addresses.";
      type = lib.types.uniq lib.types.str;
    };
    hostDomain = lib.mkOption {
      description = "The domain of the MX host.";
      type = lib.types.uniq lib.types.str;
    };
    acme = {
      email = lib.mkOption {
        description = "The email used for CA account creation.";
        type = lib.types.uniq lib.types.str;
      };
    };
    accounts = lib.mkOption {
      description = "For each email address name, its account configuration.";
      default = [ ];
      type =
        lib.types.submodule {
          options = {
            hashedPassword = lib.mkOption {
              description = "The hashed password of the account.";
              type = lib.types.uniq lib.types.str;
            };
            aliasNames = lib.mkOption {
              description = "The list of names of the alias email addresses.";
              default = [ ];
              type = lib.types.listOf lib.types.str;
            };
          };
        }
        |> lib.types.attrsOf;
    };
  };

  config = lib.mkIf config.modules.networking.mailserver.enable {
    mailserver = {
      enable = true;
      fqdn = config.modules.networking.mailserver.hostDomain;
      domains = [ config.modules.networking.mailserver.addressDomain ];

      enableImap = false;
      enableImapSsl = true;
      enableManageSieve = false;
      enablePop3 = false;
      enablePop3Ssl = false;
      enableSubmission = false;
      enableSubmissionSsl = true;

      hierarchySeparator = "/";
      lmtpSaveToDetailMailbox = "no";

      mailboxes = {
        Drafts = {
          auto = "subscribe";
          specialUse = "Drafts";
        };
        Junk = {
          auto = "subscribe";
          specialUse = "Junk";
        };
        Sent = {
          auto = "subscribe";
          specialUse = "Sent";
        };
        Trash = {
          auto = "no";
          specialUse = "Trash";
        };
      };

      loginAccounts =
        config.modules.networking.mailserver.accounts
        |> builtins.mapAttrs (
          name: accountConfig: {
            inherit (accountConfig) hashedPassword;
            aliases =
              accountConfig.aliasNames
              |> builtins.map (name: "${name}@${config.modules.networking.mailserver.addressDomain}");
          }
        );

      openFirewall = false;
      certificateScheme = "acme-nginx";
    };

    security.acme = {
      acceptTerms = true;
      certs.${config.modules.networking.mailserver.hostDomain} = {
        inherit (config.modules.networking.mailserver.acme) email;
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      465
      993
    ];
  };
}
