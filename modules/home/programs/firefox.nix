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
          SearchEngines = {
            Add = [
              {
                Name = "Qwant";
                URLTemplate = "https://www.qwant.com/?q={searchTerms}&t=all";
                IconURL = "https://www.qwant.com/favicon.ico";
                Aliases = [
                  "@q"
                  "@qwant"
                ];
              }
            ];
          };
        };
        profiles = {
          default = {
            isDefault = true;
            # Use Firefox's built-in Qwant engine id for the managed profile.
            search = {
              default = "qwant";
              privateDefault = "qwant";
              force = true;
              order = [ "qwant" ];
              engines = {
                qwant = {
                  name = "Qwant";
                  metaData.alias = "@q";
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
              "browser.startup.page" = 1;
              "browser.startup.homepage" = "http://server.tail7e8d6c.ts.net:8082";
            };
          };
        };
      };
    };
}
