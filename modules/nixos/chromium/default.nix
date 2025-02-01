{
  lib,
  options,
  config,
  pkgs,
  inputs,
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

    programs.chromium = let
      inherit (config.modules) searx;
    in rec {
      enable = true;

      defaultSearchProviderEnabled = true;
      defaultSearchProviderSuggestURL
        = "http://localhost:${builtins.toString searx.port}/search?q={searchTerms}";
      defaultSearchProviderSearchURL
        = "http://localhost:${builtins.toString searx.port}/search?q={searchTerms}";

      homepageLocation = if searx.enable then
        "localhost:${builtins.toString config.modules.searx.port}"
      else
        "https://duckduckgo.com/";

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
