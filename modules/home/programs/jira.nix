# Jira CLI integration and helpers
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Prefer jira-cli-go (ankitpokhrel/jira-cli). Fallback to go-jira if needed.
  unstable = inputs."nixpkgs-unstable".legacyPackages.${pkgs.system};
  jiraPkg =
    if unstable ? jira-cli-go then
      unstable.jira-cli-go
    else if pkgs ? jira-cli-go then
      pkgs.jira-cli-go
    else
      pkgs.go-jira;
in
{
  # Install Jira CLI for the user
  home.packages = [ jiraPkg ];

  # Provide an example config (do not store tokens in the repo)
  xdg.configFile.".jira/config.example.yml".text = ''
    # Jira CLI configuration (ankitpokhrel/jira-cli)
    #
    # 1) Initialize interactively:
    #    jira init
    #
    # 2) Or copy this to config.yml and edit values:
    #    cp ~/.config/.jira/config.example.yml ~/.config/.jira/.config.yml
    #
    # 3) Prefer setting secrets via environment variables (not in this file):
    #    export JIRA_API_TOKEN=...  JIRA_EMAIL=...  JIRA_BASE_URL=...

    # Required
    server: https://your-domain.atlassian.net
    login: mail@ludovicvanasse.com
    # apiToken: "$JIRA_API_TOKEN"  # use env; do not hardcode

    # Optional defaults
    # project: ABC
    # board: 123
    # browseUrl: https://your-domain.atlassian.net/browse
  '';

  # Fish helpers and abbreviations (only if fish is enabled)
  programs.fish = lib.mkIf config.programs.fish.enable {
    functions = {
      # Wrapper so any `jira` invocation auto-loads the token.
      # Ensure the helper is available even if autoload hasn't fired yet.
      jira = {
        description = "jira-cli with auto token export";
        wraps = "jira";
        body = ''
          if not functions -q _jira_load_env
            if test -f "$HOME/.config/fish/functions/_jira_load_env.fish"
              source "$HOME/.config/fish/functions/_jira_load_env.fish" 2>/dev/null
            end
          end
          _jira_load_env 2>/dev/null
          command jira $argv
        '';
      };
      # Ensure JIRA_API_TOKEN is exported from the decrypted secret if present
      "_jira_load_env" = {
        description = "Export JIRA_API_TOKEN from ~/.config/.jira/JIRA_API_TOKEN (fallback: ~/.config/jira)";
        body = ''
          set -l tok1 "$HOME/.config/.jira/JIRA_API_TOKEN"
          set -l tok2 "$HOME/.config/jira/JIRA_API_TOKEN"
          set -l t ""
          if test -f $tok1
            set t (string trim -- (cat $tok1))
          else if test -f $tok2
            set t (string trim -- (cat $tok2))
          end
          if test -n "$t"
            set -gx JIRA_API_TOKEN "$t"
          end
        '';
      };
      # List my active issues with a concise table
      "jira-me" = {
        description = "List my Jira issues (To Do/In Progress/In Review)";
        body = ''
          command -q jira; or begin
            echo "jira CLI not found in PATH"; return 127
          end
          _jira_load_env
          set -l me_user (jira me)
          jira issue list \
            -a $me_user \
            -s "To Do" -s "In Progress" -s "In Review" \
            --paginate 0:30 \
            --plain \
            --columns KEY,STATUS,PRIORITY,SUMMARY
        '';
      };

      # Open an issue in the default browser
      "jira-open" = {
        description = "Open a Jira issue in the browser";
        body = ''
          if test (count $argv) -lt 1
            echo "Usage: jira-open ISSUE-KEY"; return 2
          end
          _jira_load_env
          jira browse $argv[1]
        '';
      };

      # Show plan: current open sprint (or use JQL for open sprints)
      "jira-plan" = {
        description = "Show issues in open sprints (board default or via JQL)";
        body = ''
          command -q jira; or begin
            echo "jira CLI not found in PATH"; return 127
          end
          _jira_load_env
          # Uses JQL to show issues in any open sprint, sorted by priority
          set -l jql 'sprint in openSprints() ORDER BY priority DESC'
          jira issue list \
            --jql $jql \
            --paginate 0:50 \
            --plain \
            --columns KEY,ASSIGNEE,STATUS,PRIORITY,SUMMARY
        '';
      };
    };

    shellAbbrs = {
      # Quick views
      jl = "jira-me";
      jv = "jira issue view";
      jb = "jira browse";
    };
  };
}
