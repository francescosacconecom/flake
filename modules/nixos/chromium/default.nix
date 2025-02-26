{
  lib,
  options,
  config,
  pkgs,
  ...
}:
{
  options.modules.chromium = {
    enable = lib.mkOption {
      description = "Whether to enable Chromium.";
      default = false;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf config.modules.chromium.enable {
    environment.systemPackages = [
      pkgs.ungoogled-chromium
    ];

    programs.chromium = rec {
      enable = true;

      defaultSearchProviderEnabled = true;

      homepageLocation = "https://duckduckgo.com/";

      initialPrefs = {
        autofill = false;
        autologin = false;
        bookmark_bar = {
          show_apps_shortcut = false;
          show_managed_bookmarks = false;
          show_on_all_tabs = false;
          show_tab_groups = false;
        };
        browser = {
          enable_spellchecking = false;
          has_seen_welcome_page = true;
          show_home_button = false;
        };
        history = {
          deleting_enabled = true;
          saving_disabled = true;
        };
        homepage_is_newtabpage = true;
      };

      extraOpts = {
        BrowserSignin = 0;
        SyncDisabled = true;
        PasswordManagerEnabled = false;
        SpellcheckEnabled = false;
      };
    };
  };
}
