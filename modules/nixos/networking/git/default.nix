{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.networking.git = {
    enable = lib.mkOption {
      description = "Whether to create the Git user and set up a Git server.";
      default = false;
      type = lib.types.bool;
    };
    daemon = {
      enable = lib.mkOption {
        description = "Whether to enable Stagit.";
        default = false;
        type = lib.types.bool;
      };
    };
    stagit = {
      enable = lib.mkOption {
        description = "Whether to enable Stagit.";
        default = false;
        type = lib.types.bool;
      };
      root = lib.mkOption {
        description = "The root directory to generate the Stagit webpage in.";
        type = lib.types.uniq lib.types.path;
      };
      faviconPng = lib.mkOption {
        description = "The path to the webpage favicon.png.";
        type = lib.types.uniq lib.types.path;
      };
      logoPng = lib.mkOption {
        description = "The path to the webpage logo.png.";
        type = lib.types.uniq lib.types.path;
      };
    };
  };

  config = lib.mkIf config.modules.networking.git.enable {
    users.users.git = {
      hashedPassword = "!";
      isNormalUser = true;
      group = "git";
      createHome = true;
      home = "/srv/git";
    };

    users.groups.git = { };

    programs.git = {
      enable = true;
      package = pkgs.git;

      config = {
        init.defaultBranch = "master";
      };
    };

    services.gitDaemon =
      let
        inherit (config.modules.networking.git) daemon;
      in
      lib.mkIf daemon.enable {
        enable = true;
        package = pkgs.git;

        user = "git";
        group = "git";
        basePath = "/srv/git";
        exportAll = true;

        port = 9418;
      };

    networking.firewall.allowedTCPPorts = lib.mkIf config.modules.networking.git.daemon [
      9418
    ];

    systemd =
      let
        inherit (config.modules.networking.git) stagit;
      in
      lib.mkIf stagit.enable {
        services.stagit = {
          enable = true;
          wantedBy = [ "multi-user.target" ];
          script = ''
            ${pkgs.coreutils}/bin/ln -sf \
              ${./stagit/style.css} \
              ${stagit.root}/style.css

            ${pkgs.coreutils}/bin/ln -sf \
              ${stagit.faviconPng} \
              ${stagit.root}/favicon.png

            ${pkgs.coreutils}/bin/ln -sf \
              ${stagit.logoPng} \
              ${stagit.root}/logo.png

            ${pkgs.coreutils}/bin/echo "${pkgs.stagit}/bin/stagit-index" \
              > ${stagit.root}/.stagit-index

            for file in /srv/git/*; \
            do \
              ${pkgs.coreutils}/bin/mkdir -p \
                ${stagit.root}/$(${pkgs.coreutils}/bin/basename $file); \

              cd ${stagit.root}/$(${pkgs.coreutils}/bin/basename $file); \

              ${pkgs.stagit}/bin/stagit $file; \

              ${pkgs.coreutils}/bin/ln -sf \
                ${./stagit/style.css} \
                ${stagit.root}/$(${pkgs.coreutils}/bin/basename $file)/style.css; \

              ${pkgs.coreutils}/bin/ln -sf \
                ${stagit.faviconPng} \
                ${stagit.root}/$(${pkgs.coreutils}/bin/basename $file)/favicon.png; \

              ${pkgs.coreutils}/bin/ln -sf \
                ${stagit.logoPng} \
                ${stagit.root}/$(${pkgs.coreutils}/bin/basename $file)/logo.png; \

              echo " $file" >> ${stagit.root}/.stagit-index; \
            done

            eval $(${pkgs.coreutils}/bin/cat ${stagit.root}/.stagit-index) > ${stagit.root}/index.html

            rm ${stagit.root}/.stagit-index
          '';
        };
      };
  };
}
