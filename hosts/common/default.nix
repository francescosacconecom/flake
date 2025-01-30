{
  config,
  pkgs,
  ...
}:
{
  system.stateVersion = "23.11";

  users = {
    mutableUsers = false;
    users."root".hashedPassword = "!";
  };

  networking.firewall = {
    enable = true;
    package = pkgs.iptables;
  };

  security.acme.defaults.webroot = "/var/lib/acme/acme-challenge";

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
      dates = "daily";
      options = "--delete-older-than 1d";
    };
  };
}
