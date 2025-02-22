{
  config,
  pkgs,
  ...
}:
{
  system.stateVersion = "23.11";

  users = {
    mutableUsers = false;
    defaultUserShell = "${pkgs.yash}/bin/yash";
    users.root = {
      hashedPassword = "!";
    };
  };

  networking.firewall = {
    enable = true;
    package = pkgs.iptables;
  };

  environment.defaultPackages = [ ];

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
