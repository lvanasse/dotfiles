{ ... }:
{
  flake.modules.homeManager."programs.firefox" =
    { ... }:
    {
      programs.firefox = {
        enable = true;
        # Enforce default search engine at the browser level for all profiles
        policies = {
          DefaultSearchEngine = "Qwant";
          DefaultSearchEnginePrivate = "Qwant";
          SearchSuggestEnabled = false;
          Preferences = {
            "browser.urlbar.placeholderName" = {
              Value = "Qwant";
              Status = "locked";
            };
            "browser.urlbar.placeholderName.private" = {
              Value = "Qwant";
              Status = "locked";
            };
            "browser.search.suggest.enabled" = {
              Value = false;
              Status = "locked";
            };
          };
        };
        profiles = {
          default = {
            isDefault = true;
            # Define Qwant explicitly; the built-in engine is locale-dependent.
            search = {
              default = "qwant";
              privateDefault = "qwant";
              force = true;
              order = [ "qwant" ];
              engines = {
                qwant = {
                  name = "Qwant";
                  urls = [
                    {
                      template = "https://www.qwant.com/";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                        {
                          name = "t";
                          value = "all";
                        }
                      ];
                    }
                  ];
                  iconMapObj."16" = "https://www.qwant.com/favicon.ico";
                  definedAliases = [
                    "@q"
                    "@qwant"
                  ];
                };
                google = {
                  metaData.hidden = true;
                };
                bing = {
                  metaData.hidden = true;
                };
                duckduckgo = {
                  metaData.hidden = true;
                };
                ebay = {
                  metaData.hidden = true;
                };
                wikipedia = {
                  metaData.hidden = true;
                };
                perplexity = {
                  metaData.hidden = true;
                };
              };
            };

            settings = {
              # Minimal privacy-friendly defaults
              "browser.search.suggest.enabled" = false;
              "browser.search.openintab" = true;
              "browser.urlbar.placeholderName" = "Qwant";
              "browser.urlbar.placeholderName.private" = "Qwant";
              "browser.startup.page" = 1;
              "browser.startup.homepage" = "http://server.tail7e8d6c.ts.net:8082";
            };
          };
        };
      };
    };
}
