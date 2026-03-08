{ ... }:
{
  flake.modules.homeManager."terminal.fish" =
    { pkgs, ... }:
    {
      # Fish shell configuration
      programs.fish = {
        enable = true;

        # Fish with Starship prompt (minimal theme)
        interactiveShellInit = ''
          # Set fish greeting
          set fish_greeting

          # Load Nix environment (Fish) when available
          if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
          else if test -f /nix/var/nix/profiles/default/etc/profile.d/nix.fish
            source /nix/var/nix/profiles/default/etc/profile.d/nix.fish
          end

          # Use a minimal Starship config inside Emacs/vterm to avoid artifacts
          if set -q INSIDE_EMACS
            set -gx STARSHIP_CONFIG "$HOME/.config/starship-emacs.toml"
          end

          # Enable Starship prompt when available
          if type -q starship
            starship init fish | source
          end

          # Load bass plugin to run Bash commands in Fish
          if test -f ${pkgs.fishPlugins.bass}/share/fish/vendor_functions.d/bass.fish
            source ${pkgs.fishPlugins.bass}/share/fish/vendor_functions.d/bass.fish
          end

          # Ensure local user scripts and npm globals are first on PATH
          if type -q fish_add_path
            fish_add_path -m $HOME/.npm-global/bin
            fish_add_path -m $HOME/.local/bin
          else
            if not contains -- $HOME/.npm-global/bin $PATH
              set -gx PATH $HOME/.npm-global/bin $PATH
            end
            if not contains -- $HOME/.local/bin $PATH
              set -gx PATH $HOME/.local/bin $PATH
            end
          end

          # Add Snap binaries when available (Ubuntu/non-NixOS)
          if test -d /snap/bin; and not contains -- /snap/bin $PATH
            set -gx PATH /snap/bin $PATH
          end

          # Make autocomplete/suggestions and arguments less colorful
          # - Keep arguments neutral white instead of blue
          # - Show autosuggestions as dim gray
          set -g fish_color_param white
          set -g fish_color_valid_path white
          set -g fish_color_autosuggestion brblack

          # Set some useful aliases
          alias ll "ls -la"
          alias la "ls -la"
          alias l "ls -l"
          alias .. "cd .."
          alias ... "cd ../.."

          # Git aliases (fish has great git integration already)
          alias gs "git status"
          alias ga "git add"
          alias gc "git commit"
          alias gp "git push"
          alias gl "git log --oneline"
          alias screenshot "screenshot-annotate"

        '';

        # Fish plugins for enhanced functionality
        # Note: Removed Tide plugin due to hash mismatch - fish has great built-in git support anyway
        plugins = [
          {
            name = "bass";
            src = pkgs.fishPlugins.bass;
          }
          # Auto-suggestions and syntax highlighting are built into fish
        ];

        # Shell abbreviations (like aliases but expand when you type them)
        shellAbbrs = {
          # Git abbreviations
          gst = "git status";
          gaa = "git add --all";
          gcm = "git commit -m";
          gco = "git checkout";
          gp = "git push";
          gl = "git pull";

          # System abbreviations
          ll = "ls -la";
          la = "ls -la";
          l = "ls -l";

          # Nix abbreviations
          nfc = "nix flake check";
        };

        # Functions
        functions = {
          # Pretty command-not-found hook with helpful Nix hints
          fish_command_not_found = {
            description = "Pretty command-not-found with Nix hints";
            body = ''
              set -l cmd $argv[1]
              set -l bold (set_color --bold)
              set -l red (set_color red)
              set -l normal (set_color normal)

              echo "$bold$red✗$normal Command not found:$bold $cmd$normal" 1>&2
              echo "Tips:" 1>&2
              echo "  • Search in nixpkgs:  nix search nixpkgs $cmd" 1>&2
              echo "  • Try a package:      nix run nixpkgs#<package> -- <args>" 1>&2
              echo "  • In a shell:         nix shell nixpkgs#<package> -c <command>" 1>&2

              # Return standard 127 not-found code
              return 127
            '';
          };
          # Add bash-like `sudo !!` support for fish
          sudo = {
            wraps = "sudo";
            description = "Run last command with sudo when invoked as `sudo !!`";
            body = ''
              if test (count $argv) -eq 1; and test "$argv[1]" = "!!"
                set -l last (history | head -n1)
                if test -n "$last"
                  eval command sudo $last
                  return $status
                end
              end
              command sudo $argv
            '';
          };

          # Custom function to show git status in a nice way
          gitinfo = {
            body = ''
              if git rev-parse --git-dir > /dev/null 2>&1
                echo "📁 Repository: "(basename (git rev-parse --show-toplevel))
                echo "🌿 Branch: "(git branch --show-current)
                echo "📊 Status:"
                git status --short
              else
                echo "Not in a git repository"
              end
            '';
            description = "Show detailed git information";
          };

          # Function to quickly navigate to your dotfiles
          dotfiles = {
            body = "cd $HOME/Code/personal/dotfiles";
            description = "Navigate to dotfiles directory";
          };

          # Unified nix-switch for both NixOS and standalone Home Manager
          nix-switch = {
            description = "Switch NixOS/Home Manager configuration";
            body = ''
              set -l flake_dir "$HOME/Code/personal/dotfiles"
              if set -q NH_FLAKE
                set flake_dir "$NH_FLAKE"
              end
              bash "$flake_dir/scripts/nix-switch.sh" $argv
            '';
          };

          # Wrapper for local HM+NixOS switch or remote target-host switch
          nohm = {
            description = "Run nh-os-with-home locally or nh os switch for remote targets";
            body = ''
              if test (count $argv) -lt 1
                echo "Usage: nohm <host> [--target-host user@ip] [extra nh args]" >&2
                return 1
              end

              set -l host $argv[1]
              set -l rest $argv
              set -e rest[1]

              if test "$host" = "hm-only"
                if contains -- --target-host $argv
                  echo "nohm: --target-host is not supported for hm-only; run nix-switch on that machine." >&2
                  return 1
                end
                nix-switch $argv
                return $status
              end

              if contains -- --target-host $argv
                command nh os switch -H $host $rest
              else
                command nh-os-with-home $argv
              end
            '';
          };

          # Set terminal/window title to the full path like Starship's directory module
          # - Use ~ for home
          # - No truncation/shortening (matches starship.directory.truncation_length = 0)
          fish_title = {
            description = "Set terminal title to current directory path (~ for home)";
            body = ''
              set -l cwd $PWD
              # Replace $HOME with ~ for a cleaner title
              set cwd (string replace -r "^$HOME" "~" -- $cwd)
              echo $cwd
            '';
          };
        };
      };
    };
}
