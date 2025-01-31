{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.networking.syncthing = {
    enable = lib.mkOption {
      description = "Whether to enable Syncthing.";
      default = false; type = lib.types.bool;
    };
    root = lib.mkOption {
      description = "The root directory where Syncthing folders will reside.";
      type = lib.types.uniq lib.types.path;
    };
    announce = {
      enable = lib.mkOption {
        description = "Whether to send announcements to the local LAN.";
        default = false;
        type = lib.types.bool;
      };
    };
    folders = lib.mkOption {
      description = "For each folder ID, its configuration.";
      default = { };
      type = lib.types.submodule {
        options = {
          devices = lib.mkOption {
            description = "The list of device IDs which will have access to the folder.";
            type = lib.types.listOf lib.types.str;
          };
        };
      }
      |> lib.types.attrsOf;
    };
  };

  config = lib.mkIf config.modules.networking.syncthing.enable {
    users.users.syncthing = {
      hashedPassword = "!";
      isNormalUser = true;
      group = "syncthing";
      createHome = true;
      home = config.modules.networking.syncthing.root;
    };

    users.groups.syncthing = { };

    services.syncthing = {
      enable = true;
      package = pkgs.syncthing;

      user = "syncthing";
      group = "syncthing";

      urAccepted = -1;
      openDefaultPorts = false;
      relay.enable = false;
      systemService = true;

      dataDir = config.modules.networking.syncthing.root;

      settings = {
        options = let
          inherit (config.modules.networking.syncthing) announce;
        in {
          relaysEnabled = true;
          localAnnounceEnabled = announce.enable;
          localAnnouncePort = lib.mkIf announce.enable 21027;
          limitBandwidthInLan = false;
        };
        folders =
          config.modules.networking.syncthing.folders
          |> builtins.mapAttrs (
            folderId: folderConfig: {
              path = "~/${folderId}";

              id = folderId;
              inherit (folderConfig) devices;

              type = "sendreceive";
              versioning.type = "simple";
            }
          );
        devices =
            config.modules.networking.syncthing.folders
            |> builtins.attrValues
            |> builtins.map (folderConfig: folderConfig.devices)
            |> builtins.concatLists
            |> builtins.map (
              device: {
                name = device;
                value = {
                  autoAcceptFolders = true;
                  id = device;
                };
              }
            )
            |> builtins.listToAttrs;
      };
    };

    networking.firewall.allowedTCPPorts =
      [
        22000
      ] ++ if config.modules.networking.syncthing.announce.enable then
        [
          21027
        ]
      else
        [ ];
  };
}
