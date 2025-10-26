_: {
  programs.firefox = {
    enable = true;
    profiles = {
      default = {
        isDefault = true;
        # Force a privacy-friendly, libre meta-search engine by default (SearXNG)
        search = {
          default = "SearXNG";
          force = true;
          engines = {
            "SearXNG" = {
              urls = [
                {
                  # Use explicit query template; params sometimes misbehave across versions
                  template = "https://search.rhscz.eu/search?q={searchTerms}";
                }
              ];
              searchForm = "https://search.rhscz.eu/";
              icon = "https://search.rhscz.eu/favicon.ico";
              definedAliases = [
                "@sx"
                "@searx"
              ];
            };
          };
        };

        settings = {
          # Minimal privacy-friendly defaults
          "browser.search.suggest.enabled" = false;
          "browser.search.openintab" = true;
          "browser.startup.page" = 3; # restore previous session
        };
      };
    };
  };
}
