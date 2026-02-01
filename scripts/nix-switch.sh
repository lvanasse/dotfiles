#!/bin/bash
# Unified Nix switch script for both NixOS and standalone Home Manager
# Usage: ./scripts/nix-switch.sh <hostname> [-- <extra nh os args>]
#
# On NixOS:     runs home-manager switch, then nh os switch
# On non-NixOS: runs home-manager switch, then symlinks wayland sessions for GDM

set -euo pipefail

USERNAME="ludovic"
FLAKE_DIR="${NH_FLAKE:-$HOME/Code/personal/dotfiles}"

if [ $# -lt 1 ]; then
    echo "Usage: nix-switch <hostname> [-- <extra nh os args>]" >&2
    echo "Examples:" >&2
    echo "  nix-switch pc" >&2
    echo "  nix-switch laptop" >&2
    echo "  nix-switch hm-only" >&2
    exit 1
fi

HOST="$1"
shift

# Collect extra args (everything after --)
EXTRA_ARGS=""
while [ $# -gt 0 ]; do
    if [ "$1" = "--" ]; then
        shift
        EXTRA_ARGS="$*"
        break
    fi
    shift
done

cd "$FLAKE_DIR"

is_nixos() {
    [ -f /etc/NIXOS ]
}

# Pre-switch: remove conflicting files that Home Manager will manage
echo "==> Removing conflicting files..."
rm -f "$HOME/.config/Code/User/settings.json" 2>/dev/null || true
rm -rf "$HOME/.vscode/extensions" 2>/dev/null || true
rm -f "$HOME/.local/share/applications/mimeapps.list" 2>/dev/null || true

# Step 1: Home Manager switch (always)
BEXT="${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
echo "==> [1/2] Home Manager: home-manager switch --flake ${FLAKE_DIR}#${USERNAME}@${HOST} -b ${BEXT}"
home-manager switch --flake "${FLAKE_DIR}#${USERNAME}@${HOST}" -b "${BEXT}"

# Step 2: NixOS or post-switch tasks
if is_nixos; then
    echo "==> [2/2] NixOS: nh os switch -H ${HOST} ${EXTRA_ARGS}"
    # shellcheck disable=SC2086
    NH_FLAKE="${FLAKE_DIR}" nh os switch -H "${HOST}" $EXTRA_ARGS
else
    # Non-NixOS: symlink Wayland session files for GDM visibility
    WAYLAND_SESSIONS_SRC="$HOME/.nix-profile/share/wayland-sessions"
    WAYLAND_SESSIONS_DST="/usr/share/wayland-sessions"

    if [ -d "$WAYLAND_SESSIONS_SRC" ]; then
        echo "==> [2/2] Symlinking Wayland session files for GDM..."
        for session in "$WAYLAND_SESSIONS_SRC"/*.desktop; do
            [ -f "$session" ] || continue
            name=$(basename "$session")
            target="$WAYLAND_SESSIONS_DST/$name"
            if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$session" ]; then
                sudo ln -sf "$session" "$target"
                echo "    Linked: $name"
            else
                echo "    Already linked: $name"
            fi
        done
    else
        echo "==> [2/2] No Wayland sessions to link (skipped)"
    fi
fi

echo "==> Done!"
