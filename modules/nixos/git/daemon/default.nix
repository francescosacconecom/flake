{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.git.daemon = {
    enable = lib.mkOption {
      description = "Whether to enable the Git daemon.";
      default = false;
      type = lib.types.bool;
    };
  };

  config =
    let
      inherit (config.modules.git) daemon;
    in
    lib.mkIf (config.modules.git.enable && daemon.enable) {
      systemd = {
        services = {
          git-daemon = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              Restart = "always";
              RestartSec = "500ms";
              User = "git";
              Group = "git";
            };
            script = ''
              ${pkgs.git}/bin/git daemon \
                --verbose \
                --base-path=${config.modules.git.directory}
                --reuseaddr \
                --timeout=1 \
                --max-connections=0 \
                --listen=localhost \
                --port=9418 \
                --export-all ${
                  (
                    config.modules.git.repositories
                    |> builtins.attrNames
                    |> builtins.map (name: "${config.modules.git.directory}/${name}")
                    |> builtins.concatStringsSep " "
                  )
                }
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 9418 ];
    };
}
