{ ... }:
{
  flake.modules.homeManager."host.laptop-ubuntu" =
    { pkgs, ... }:
    {
      # Host-specific overrides for the Ubuntu ThinkPad go here.
      home.packages = [
        (pkgs.writeShellScriptBin "sway-install-session" ''
          set -euo pipefail

          if [ "$EUID" -ne 0 ]; then
            echo "Run with sudo to install the system Sway session:" >&2
            echo "  sudo sway-install-session" >&2
            exit 1
          fi

          if [ -z "''${SUDO_USER:-}" ]; then
            echo "Missing SUDO_USER; run from your user account with sudo." >&2
            exit 1
          fi

          user="''${SUDO_USER}"
          home_dir="$(getent passwd "$user" | cut -d: -f6)"
          if [ -z "$home_dir" ]; then
            echo "Unable to resolve home directory for $user" >&2
            exit 1
          fi

          src="$home_dir/.local/share/wayland-sessions/sway.desktop"
          dest="/usr/share/wayland-sessions/sway.desktop"

          if [ ! -f "$src" ]; then
            echo "Missing $src. Run home-manager switch first." >&2
            exit 1
          fi

          install -m 0644 "$src" "$dest"
          echo "Installed $dest"
        '')
      ];
    };
}
