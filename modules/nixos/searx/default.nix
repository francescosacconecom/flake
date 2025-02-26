{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.searx = {
    enable = lib.mkOption {
      description = "Whether to enable Searx.";
      default = false;
      type = lib.types.bool;
    };
    port = lib.mkOption {
      description = "The local port that Searx is hosted in.";
      type = lib.types.uniq lib.types.int;
    };
  };

  config = lib.mkIf config.modules.searx.enable {
    systemd.services.generate-searx-secret-key = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      before = [ "searx.service" ];
      serviceConfig =
        let
          script = pkgs.writeShellScriptBin "script" ''
            export SEARX_SECRET_KEY=$(${pkgs.coreutils}/bin/head -c 32 \
            /dev/urandom | ${pkgs.coreutils}/bin/base64 |\
            ${pkgs.coreutils}/bin/tr -d '\n')
          '';
        in
        {
          User = "searx";
          Group = "searx";
          Type = "oneshot";
          ExecStart = "${script}/bin/script";
        };
    };

    services.searx = {
      enable = true;

      settings.server = {
        bind_address = "localhost";
        inherit (config.modules.searx) port;
        secret_key = "@SEARX_SECRET_KEY@";
      };
    };
  };
}
