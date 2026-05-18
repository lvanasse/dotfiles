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
          vem = "$HOME/.local/bin/term-emacs";
        };

        initExtra = ''
          # Load Nix environment (Bash) when available
          if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          elif [ -f /nix/var/nix/profiles/default/etc/profile.d/nix.sh ]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi

          # Recover from stale SSH_AUTH_SOCK (for example a dead terminal-managed agent socket)
          _gcr_ssh="/run/user/$(id -u)/gcr/ssh"
          _keyring_ssh="/run/user/$(id -u)/keyring/ssh"
          if [ -n "''${SSH_AUTH_SOCK:-}" ] && [ ! -S "$SSH_AUTH_SOCK" ]; then
            if [ -S "$_gcr_ssh" ]; then
              export SSH_AUTH_SOCK="$_gcr_ssh"
            elif [ -S "$_keyring_ssh" ]; then
              export SSH_AUTH_SOCK="$_keyring_ssh"
            else
              unset SSH_AUTH_SOCK
            fi
          elif [ -z "''${SSH_AUTH_SOCK:-}" ]; then
            if [ -S "$_gcr_ssh" ]; then
              export SSH_AUTH_SOCK="$_gcr_ssh"
            elif [ -S "$_keyring_ssh" ]; then
              export SSH_AUTH_SOCK="$_keyring_ssh"
            fi
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

          # Single switch entrypoint for local HM+NixOS and standalone Home Manager.
          nohm() {
            local flake_dir="''${NH_FLAKE:-$HOME/Code/personal/dotfiles}"
            if [ "$#" -ge 1 ] && [ "$1" = "auth" ]; then
              bash "$flake_dir/scripts/setup-sway-auth.sh"
              return $?
            fi
            bash "$flake_dir/scripts/nix-switch.sh" "$@"
          }
        '';
      };
    };
}
