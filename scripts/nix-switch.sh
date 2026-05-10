#!/bin/bash
# Internal switch implementation for `nohm`
# Usage: nohm <hostname> [-- <extra nh os args>]
#
# On NixOS:     runs home-manager switch, then nh os switch
# On non-NixOS: runs home-manager switch, then symlinks wayland sessions for GDM

set -euo pipefail

USERNAME="ludovic"
FLAKE_DIR="${NH_FLAKE:-$HOME/Code/personal/dotfiles}"

if [ $# -lt 1 ]; then
    echo "Usage: nohm <hostname> [-- <extra nh os args>]" >&2
    echo "Examples:" >&2
    echo "  nohm pc" >&2
    echo "  nohm laptop" >&2
    echo "  nohm hm-only" >&2
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

should_validate_spacemacs() {
    case "$HOST" in
        pc|laptop|hm-only) return 0 ;;
        *) return 1 ;;
    esac
}

is_nixos() {
    [ -f /etc/NIXOS ]
}

resolve_nix_config() {
    local reserve_cores build_cores total_cores available_cores max_jobs

    reserve_cores="${MACHINE_RESERVED_CORES:-${NOHM_RESERVED_CORES:-2}}"
    case "$reserve_cores" in
        ''|*[!0-9]*) reserve_cores=2 ;;
    esac

    total_cores="$(nproc)"
    case "$total_cores" in
        ''|*[!0-9]*) total_cores=1 ;;
    esac

    available_cores=$(( total_cores - reserve_cores ))
    if [ "$available_cores" -lt 1 ]; then
        available_cores=1
    fi

    build_cores="${MACHINE_BUILD_CORES:-${NOHM_BUILD_CORES:-auto}}"
    case "$build_cores" in
        ''|auto) build_cores="$available_cores" ;;
        *[!0-9]*) build_cores="$available_cores" ;;
    esac
    if [ "$build_cores" -lt 1 ]; then
        build_cores=1
    elif [ "$build_cores" -gt "$available_cores" ]; then
        build_cores="$available_cores"
    fi

    max_jobs=$(( available_cores / build_cores ))
    if [ "$max_jobs" -lt 1 ]; then
        max_jobs=1
    fi

    printf 'experimental-features = nix-command flakes\nmax-jobs = %s\ncores = %s\n' "$max_jobs" "$build_cores"
}

NIX_WRAPPER_CONFIG="$(resolve_nix_config)"
if [ -n "${NIX_CONFIG:-}" ]; then
    NIX_WRAPPER_CONFIG="${NIX_WRAPPER_CONFIG}
${NIX_CONFIG}
"
fi
WRAPPER_MAX_JOBS="$(printf '%s' "$NIX_WRAPPER_CONFIG" | awk -F' = ' '/^max-jobs = / { print $2; exit }')"
WRAPPER_BUILD_CORES="$(printf '%s' "$NIX_WRAPPER_CONFIG" | awk -F' = ' '/^cores = / { print $2; exit }')"
WRAPPER_RESERVED_CORES="${MACHINE_RESERVED_CORES:-${NOHM_RESERVED_CORES:-2}}"
echo "==> Nix limits: leave ${WRAPPER_RESERVED_CORES} machine core(s) free, build cores ${WRAPPER_BUILD_CORES}, max-jobs ${WRAPPER_MAX_JOBS}"

# Pre-switch: remove conflicting files that Home Manager will manage
echo "==> Removing conflicting files..."
rm -f "$HOME/.config/Code/User/settings.json" 2>/dev/null || true
rm -rf "$HOME/.vscode/extensions" 2>/dev/null || true
rm -f "$HOME/.local/share/applications/mimeapps.list" 2>/dev/null || true

# Step 1: Home Manager switch (always)
BEXT="${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
echo "==> [1/2] Home Manager: home-manager switch --flake ${FLAKE_DIR}#${USERNAME}@${HOST} -b ${BEXT}"
NIX_CONFIG="${NIX_WRAPPER_CONFIG}" home-manager switch --flake "${FLAKE_DIR}#${USERNAME}@${HOST}" -b "${BEXT}"

if should_validate_spacemacs && [ -x "$FLAKE_DIR/scripts/validate-spacemacs.sh" ]; then
    echo "==> [1.5/2] Validating Spacemacs config..."
    "$FLAKE_DIR/scripts/validate-spacemacs.sh" "$HOME/.spacemacs" "$HOME/.emacs.d"
fi

# Step 2: NixOS or post-switch tasks
if is_nixos && [ "$HOST" != "hm-only" ]; then
    echo "==> [2/2] NixOS: nh os switch -H ${HOST} ${EXTRA_ARGS}"
    # shellcheck disable=SC2086
    NH_FLAKE="${FLAKE_DIR}" NIX_CONFIG="${NIX_WRAPPER_CONFIG}" nh os switch -H "${HOST}" $EXTRA_ARGS
elif is_nixos && [ "$HOST" = "hm-only" ]; then
    echo "==> [2/2] hm-only target detected; skipping NixOS switch"
else
    # Non-NixOS: symlink Wayland session files for GDM visibility
    # Use ~/.local/share (home-manager managed) which has the wrapped sway path
    WAYLAND_SESSIONS_SRC="$HOME/.local/share/wayland-sessions"
    WAYLAND_SESSIONS_DST="/usr/share/wayland-sessions"
    echo "==> [2/2] Ensuring swaylock authentication support..."
    bash "$FLAKE_DIR/scripts/setup-sway-auth.sh"

    if [ -d "$WAYLAND_SESSIONS_SRC" ]; then
        echo "==> [2/2] Symlinking Wayland session files for GDM..."
        for session in "$WAYLAND_SESSIONS_SRC"/*.desktop; do
            [ -f "$session" ] || continue
            name=$(basename "$session")
            # Resolve the symlink to get the actual nix store path (GDM can't traverse ~/...)
            resolved=$(readlink -f "$session")
            target="$WAYLAND_SESSIONS_DST/$name"
            if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$resolved" ]; then
                sudo ln -sf "$resolved" "$target"
                echo "    Linked: $name -> $resolved"
            else
                echo "    Already linked: $name"
            fi
        done
    else
        echo "==> [2/2] No Wayland sessions to link (skipped)"
    fi
fi

echo "==> Done!"
