{ ... }:
{
  flake.modules.homeManager.jira =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # Prefer jira-cli-go (ankitpokhrel/jira-cli). Fallback to go-jira if needed.
      jiraPkg =
        if pkgs ? jira-cli-go then
          pkgs.jira-cli-go
        else
          pkgs.go-jira;

      # Runtime wrapper that injects JIRA_API_TOKEN from the decrypted secret for
      # every shell invocation (not just fish).
      jiraWrapper = pkgs.writeShellScriptBin "jira" ''
        set -eo pipefail

        read_token() {
          local file="$1"
          if [ -f "$file" ]; then
            local data
            data="$([ -r "$file" ] && cat "$file")"
            printf '%s' "$data"
            return 0
          fi
          return 1
        }

        primary="$HOME/.config/.jira/JIRA_API_TOKEN"
        fallback="$HOME/.config/jira/JIRA_API_TOKEN"

        if [ -z "$JIRA_API_TOKEN" ]; then
          token=""
          if token="$(read_token "$primary")"; then
            export JIRA_API_TOKEN="$token"
          elif token="$(read_token "$fallback")"; then
            export JIRA_API_TOKEN="$token"
          fi
        fi

        if [ -z "$JIRA_API_TOKEN" ]; then
          printf 'jira: could not find JIRA_API_TOKEN at %s (or %s).\n' "$primary" "$fallback" 1>&2
          printf 'Hint: sync ~/Code/personal/secrets and re-run agenix to refresh secrets.\n' 1>&2
          exit 1
        fi

        exec ${jiraPkg}/bin/jira "$@"
      '';

      # Expose the unwrapped CLI as `jira-cli` for manual use/debugging.
      jiraTools = pkgs.runCommand "jira-cli-tools" { } ''
        mkdir -p $out/bin
        ln -s ${jiraPkg}/bin/jira $out/bin/jira-cli
      '';

      helperRuntimeInputs = with pkgs; [
        coreutils
        gnused
      ];

      commonFunctions = ''
        set -euo pipefail

        require_jira() {
          if ! command -v jira >/dev/null 2>&1; then
            echo "jira CLI not found in PATH" >&2
            exit 127
          fi
        }

        load_jira_token() {
          local token_file=""
          if [ -f "$HOME/.config/.jira/JIRA_API_TOKEN" ]; then
            token_file="$HOME/.config/.jira/JIRA_API_TOKEN"
          elif [ -f "$HOME/.config/jira/JIRA_API_TOKEN" ]; then
            token_file="$HOME/.config/jira/JIRA_API_TOKEN"
          fi

          if [ -n "$token_file" ]; then
            local token
            token="$(tr -d '\r' < "$token_file")"
            token="$(printf '%s' "$token" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            if [ -n "$token" ]; then
              export JIRA_API_TOKEN="$token"
            fi
          fi
        }
      '';

      mkJiraHelper =
        { name, body }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = helperRuntimeInputs;
          text = ''
            ${commonFunctions}

            ${body}
          '';
        };

      jiraHelperPackages = [
        (mkJiraHelper {
          name = "jira-me";
          body = ''
            require_jira
            load_jira_token

            me_user="$(jira me)"
            jira issue list \
              -a "$me_user" \
              -s "To Do" -s "In Progress" -s "In Review" \
              --paginate 0:30 \
              --plain \
              --columns KEY,STATUS,PRIORITY,SUMMARY
          '';
        })
        (mkJiraHelper {
          name = "jira-plan";
          body = ''
            require_jira
            load_jira_token

            jql='sprint in openSprints() ORDER BY priority DESC'
            jira issue list \
              --jql "$jql" \
              --paginate 0:50 \
              --plain \
              --columns KEY,ASSIGNEE,STATUS,PRIORITY,SUMMARY
          '';
        })
        (mkJiraHelper {
          name = "jira-open";
          body = ''
            if [ "$#" -lt 1 ]; then
              printf 'Usage: jira-open ISSUE-KEY\n' >&2
              exit 2
            fi

            require_jira
            load_jira_token

            jira browse "$1"
          '';
        })
      ];
    in
    {
      # Install the wrapped Jira CLI plus helpers and expose raw binary as jira-cli.
      home.packages = [
        jiraWrapper
        jiraTools
      ]
      ++ jiraHelperPackages;

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
              if set -q JIRA_API_TOKEN
                command jira $argv
                return
              end
              _jira_load_env 2>/dev/null
              command jira $argv
            '';
          };
          # Ensure JIRA_API_TOKEN is exported from the decrypted secret if present
          "_jira_load_env" = {
            description = "Export JIRA_API_TOKEN from ~/.config/.jira/JIRA_API_TOKEN (fallback: ~/.config/jira)";
            body = ''
              if set -q JIRA_API_TOKEN
                return
              end
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
              else
                echo "jira: JIRA_API_TOKEN not found. Run agenix or update secrets." 1>&2
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
    };
}
