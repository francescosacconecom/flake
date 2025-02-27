{
  config,
  pkgs,
  ...
}:
{
  modules = rec {
    aerc = {
      enable = true;
      email = {
        address = "francesco@francescosaccone.com";
        folders = {
          drafts = "Drafts";
          inbox = "INBOX";
          sent = "Sent";
          trash = "Trash";
        };
        imapHost = "glacier.mxrouting.net";
        imapTlsPort = 993;
        passwordCommand = ''
          ${pkgs.pass}/bin/pass show email/francesco/password
        '';
        realName = "Francesco Saccone";
        smtpHost = "glacier.mxrouting.net";
        smtpTlsPort = 465;
        username = "francesco%40francescosaccone.com";
      };
    };
    git = {
      enable = true;
      name = "Francesco Saccone";
      email = "francesco@francescosaccone.com";
    };
    gpg = {
      enable = true;
      primaryKey = {
        fingerprint = "2BE025D27B449E55B320C44209F39C4E70CB2C24";
        file = ./openpgp.asc;
      };
      pass = {
        enable = true;
        passwords =
          [
            "email/francesco"
            "routers/home"
            "web/gandi"
            "web/google"
            "web/infomaniak"
            "web/microsoft-teams"
            "web/miur"
            "web/mxroute"
            "web/myfitp"
            "web/nexi"
            "web/thomann"
            "wifi/home"
          ]
          |> builtins.map (
            name:
            let
              otp = ./pass + "/${name}/otp.gpg";
              password = ./pass + "/${name}/password.gpg";
              username = ./pass + "/${name}/username.gpg";
            in
            (
              if builtins.pathExists otp then
                [
                  {
                    name = "${name}/otp";
                    value = otp;
                  }
                ]
              else
                [ ]
            )
            ++ (
              if builtins.pathExists password then
                [
                  {
                    name = "${name}/password";
                    value = password;
                  }
                ]
              else
                [ ]
            )
            ++ (
              if builtins.pathExists username then
                [
                  {
                    name = "${name}/username";
                    value = username;
                  }
                ]
              else
                [ ]
            )
          )
          |> builtins.concatLists
          |> builtins.listToAttrs;
      };
    };
    newsraft = {
      enable = true;
      feeds = {
        "World" = [
          {
            name = "The Washington Post World";
            url = "https://feeds.washingtonpost.com/rss/world";
          }
          {
            name = "CNN International";
            url = "http://rss.cnn.com/rss/edition.rss";
          }
        ];
      };
    };
    sway = {
      enable = true;
      bar = {
        enable = true;
      };
      fonts = {
        monospace = "IBM Plex Mono";
      };
    };
    vis = {
      enable = true;
    };
  };

  home.packages = with pkgs; [
    ardour
    helvum
    imv
    libreoffice
    lynx
    mpv
    mupdf
    musescore
    nmap
    noice
    qjackctl
    tor-browser
  ];
}
