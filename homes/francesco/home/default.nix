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
        imapHost = "mx.francescosaccone.com";
        imapTlsPort = 993;
        passwordCommand = ''
          ${pkgs.coreutils}/bin/cat ${./email.asc} | ${pkgs.gnupg}/bin/gpg --decrypt --recipient ${gpg.primaryKey.fingerprint}
        '';
        realName = "Francesco Saccone";
        smtpHost = "mx.francescosaccone.com";
        smtpTlsPort = 465;
        username = "francesco";
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
        file = ./pgp.asc;
      };
    };
    mediaViewers.enable = true;
    neovim.enable = true;
    sway = {
      enable = true;
      fonts = {
        monospace = "IBM Plex Mono";
      };
    };
    syncthing = {
      enable = true;
      port = 8384;
    };
  };

  home.packages = with pkgs; [
    ardour
    helvum
    keepassxc
    libreoffice
    monero-gui
    musescore
    qjackctl
    rsync
  ];
}
