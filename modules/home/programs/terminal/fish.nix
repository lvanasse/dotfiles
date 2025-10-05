# Fish shell configuration
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.fish = {
    enable = true;
    
    # Fish with Starship prompt (minimal theme)
    interactiveShellInit = ''
      # Set fish greeting
      set fish_greeting "Welcome to fish shell! 🐟 Using Starship with minimal theme!"
      
      # Add npm global to PATH
      set -gx PATH $HOME/.npm-global/bin $PATH
      
      # Initialize Starship prompt
      starship init fish | source
      
      # Clear starship cache if needed (for config changes)
      # starship cache clear
      
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
    };
  };
}