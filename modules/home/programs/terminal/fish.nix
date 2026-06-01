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

          # Recover from stale SSH_AUTH_SOCK (for example a dead terminal-managed agent socket)
          set -l _gcr_ssh "/run/user/"(id -u)"/gcr/ssh"
          set -l _keyring_ssh "/run/user/"(id -u)"/keyring/ssh"
          if set -q SSH_AUTH_SOCK; and not test -S "$SSH_AUTH_SOCK"
            if test -S "$_gcr_ssh"
              set -gx SSH_AUTH_SOCK "$_gcr_ssh"
            else if test -S "$_keyring_ssh"
              set -gx SSH_AUTH_SOCK "$_keyring_ssh"
            else
              set -e SSH_AUTH_SOCK
            end
          else if not set -q SSH_AUTH_SOCK
            if test -S "$_gcr_ssh"
              set -gx SSH_AUTH_SOCK "$_gcr_ssh"
            else if test -S "$_keyring_ssh"
              set -gx SSH_AUTH_SOCK "$_keyring_ssh"
            end
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
          alias vem "$HOME/.local/bin/term-emacs"
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

          # Single switch entrypoint for local HM+NixOS and remote target-host flows.
          nohm = {
            description = "Switch NixOS/Home Manager configuration";
            body = ''
              if test (count $argv) -lt 1
                echo "Usage: nohm <host>|auth [--target-host user@ip] [extra nh args]" >&2
                return 1
              end

              set -l flake_dir "$HOME/Code/personal/dotfiles"
              if set -q NH_FLAKE
                set flake_dir "$NH_FLAKE"
              end

              if test "$argv[1]" = "auth"
                bash "$flake_dir/scripts/setup-sway-auth.sh"
                return $status
              end

              set -l host $argv[1]
              set -l rest $argv
              set -e rest[1]

              function __nohm_is_home_manager_only_target --argument-names target
                contains -- $target hm-only work-laptop steamdeck
              end

              if __nohm_is_home_manager_only_target "$host"
                if contains -- --target-host $argv
                  echo "nohm: --target-host is not supported for Home Manager-only targets; run nohm on that machine." >&2
                  return 1
                end
                bash "$flake_dir/scripts/nix-switch.sh" $argv
                return $status
              end

              if command -sq nh-os-with-home
                command nh-os-with-home $argv
              else if contains -- --target-host $argv
                command nh os switch -H $host $rest
              else
                bash "$flake_dir/scripts/nix-switch.sh" $argv
                return $status
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
