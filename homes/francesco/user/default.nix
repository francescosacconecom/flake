{
  config,
  pkgs,
  ...
}:
{
  users.users."francesco" = {
    description = "Francesco Saccone";
    hashedPassword = "$y$j9T$vRuBfRJ.w.7gDgYpv.0bs.$5XDxsV44Aj8LbTrRTcUfYpRRTe01sBFG1rDvBca1q30";
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
