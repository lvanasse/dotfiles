{ ... }:
{
  flake.modules.homeManager."terminal.bash" =
    { ... }:
    {
      programs.bash = {
        enable = true;

        shellAliases = {
          # Basic aliases
          ll = "ls -la";
          la = "ls -la";
          l = "ls -l";
          ".." = "cd ..";
          "..." = "cd ../..";

          # Git aliases
          gs = "git status";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gl = "git log --oneline";
        };

        initExtra = ''
          # Load Nix environment (Bash) when available
          if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          elif [ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi

          # Ensure local user scripts are on PATH
          case ":$PATH:" in
            *":$HOME/.local/bin:"*) ;;
            *) export PATH="$HOME/.local/bin:$PATH" ;;
          esac

          # Add Snap binaries when available (Ubuntu/non-NixOS)
          if [ -d /snap/bin ]; then
            case ":$PATH:" in
              *":/snap/bin:"*) ;;
              *) export PATH="/snap/bin:$PATH" ;;
            esac
          fi

          # Unified nix-switch for both NixOS and standalone Home Manager
          nix-switch() {
            local flake_dir="''${NH_FLAKE:-$HOME/Code/personal/dotfiles}"
            bash "$flake_dir/scripts/nix-switch.sh" "$@"
          }
        '';
      };
    };
}
