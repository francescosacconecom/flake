{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.git = {
    enable = lib.mkOption {
      description = "Whether to create the Git user and set up a Git server.";
      default = false;
      type = lib.types.bool;
    };
    daemon = {
      enable = lib.mkOption {
        description = "Whether to enable Git daemon.";
        default = false;
        type = lib.types.bool;
      };
    };
  };

  config = lib.mkIf config.modules.git.enable {
    users = {
      users = {
        git = {
          hashedPassword = "!";
          isSystemUser = true;
          group = "git";
          createHome = true;
          home = "/srv/git";
          shell = "${pkgs.git}/bin/git-shell";
        };
      };
      groups = {
        git = { };
      };
    };

    programs.git = {
      enable = true;
      package = pkgs.git;

      config = {
        init.defaultBranch = "master";
      };
    };

    services.gitDaemon = lib.mkIf config.modules.git.daemon.enable {
      enable = true;
      package = pkgs.git;

      user = "git";
      group = "git";
      basePath = "/srv/git";
      exportAll = true;

      port = 9418;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf config.modules.git.daemon.enable [
      9418
    ];
  };
}
