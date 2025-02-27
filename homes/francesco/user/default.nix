{
  lib,
  config,
  pkgs,
  ...
}:
{
  users.users."francesco" = {
    description = "Francesco Saccone";
    hashedPassword = builtins.readFile ./hashedPassword |> lib.strings.trim;
    isNormalUser = true;
    extraGroups = [
      "audio"
      "networkmanager"
      "realtime"
      "wheel"
    ];
    createHome = true;
    home = "/home/francesco";
    shell = "${pkgs.bashInteractive}/bin/bash";
  };

  fonts.packages = with pkgs; [
    ibm-plex
  ];
}
