{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    chromium = {
      enable = true;
    };
    wayland = {
      enable = true;
    };
    pipewire = {
      enable = true;
    };
    networkmanager = {
      enable = true;
      randomiseMacAddress = true;
    };
    openssh.agent = {
      enable = true;
    };
    sudo = {
      enable = true;
    };
    tlp = {
      enable = true;
    };
  };

  services.flatpak.enable = true;

  boot.loader = {
    timeout = 1;
    systemd-boot = {
      enable = true;
      editor = false;
    };
  };

  i18n.defaultLocale = "en_GB.UTF-8";
  time.timeZone = "Europe/Rome";

  security.pam.loginLimits = [
    {
      domain = "@realtime";
      type = "hard";
      item = "rtprio";
      value = 20;
    }
    {
      domain = "@realtime";
      type = "soft";
      item = "rtprio";
      value = 10;
    }
    {
      domain = "@audio";
      type = "-";
      item = "rtprio";
      value = 95;
    }
    {
      domain = "@audio";
      type = "-";
      item = "memlock";
      value = "unlimited";
    }
  ];
}
