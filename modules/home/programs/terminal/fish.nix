# Fish shell configuration
_: {
  programs.fish = {
    enable = true;

    # Fish with Starship prompt (minimal theme)
    interactiveShellInit = ''
      # Set fish greeting
      set fish_greeting

      # Add npm global to PATH
      set -gx PATH $HOME/.npm-global/bin $PATH

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
    '';

    # Fish plugins for enhanced functionality
    # Note: Removed Tide plugin due to hash mismatch - fish has great built-in git support anyway
    plugins = [
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
      nrs = "nh os switch -H pc";
      hms = "home-manager switch --flake .#ludovic@pc";
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
}
