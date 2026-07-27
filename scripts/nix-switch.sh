#!/bin/bash
# Internal switch implementation for `nohm`
# Usage: nohm <hostname> [-- <extra nh os args>]
#
# On NixOS:     runs home-manager switch, then nh os switch for NixOS targets
# On non-NixOS: runs home-manager switch, then symlinks wayland sessions for GDM

set -euo pipefail

USERNAME="ludovic"
FLAKE_DIR="${NH_FLAKE:-$HOME/Code/personal/dotfiles}"
NOHM_VERBOSE="${NOHM_VERBOSE:-0}"

log_verbose() {
  if [ "$NOHM_VERBOSE" = "1" ]; then
    echo "$@"
  fi
}

log_cmd() {
  local label="$1"
  shift
  printf '%s %s\n' "$label" "$*"
}

if [ $# -lt 1 ]; then
  echo "Usage: nohm <hostname> [-- <extra nh os args>]" >&2
  echo "Examples:" >&2
  echo "  nohm pc" >&2
  echo "  nohm laptop" >&2
  echo "  nohm work-laptop" >&2
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
  pc | laptop | hm-only) return 0 ;;
  *) return 1 ;;
  esac
}

is_home_manager_only_target() {
  case "$HOST" in
  hm-only | work-laptop | steamdeck) return 0 ;;
  *) return 1 ;;
  esac
}

is_nixos() {
  [ -f /etc/NIXOS ]
}

resolve_nix_config() {
  local reserve_cores build_cores total_cores available_cores max_jobs
  local reserve_memory_mib memory_per_core_mib available_memory_mib memory_cores

  reserve_cores="${MACHINE_RESERVED_CORES:-${NOHM_RESERVED_CORES:-2}}"
  case "$reserve_cores" in
  '' | *[!0-9]*) reserve_cores=2 ;;
  esac

  total_cores="$(nproc)"
  case "$total_cores" in
  '' | *[!0-9]*) total_cores=1 ;;
  esac

  available_cores=$((total_cores - reserve_cores))
  if [ "$available_cores" -lt 1 ]; then
    available_cores=1
  fi

  reserve_memory_mib="${NOHM_RESERVED_MEMORY_MIB:-4096}"
  case "$reserve_memory_mib" in
  '' | *[!0-9]*) reserve_memory_mib=4096 ;;
  esac

  memory_per_core_mib="${NOHM_MEMORY_PER_CORE_MIB:-4096}"
  case "$memory_per_core_mib" in
  '' | *[!0-9]*) memory_per_core_mib=4096 ;;
  esac

  available_memory_mib="$(awk '/^MemAvailable:/ { print int($2 / 1024); exit }' /proc/meminfo 2>/dev/null || true)"
  case "$available_memory_mib" in
  '' | *[!0-9]*) available_memory_mib=0 ;;
  esac
  if [ "$available_memory_mib" -gt "$reserve_memory_mib" ]; then
    memory_cores=$(((available_memory_mib - reserve_memory_mib) / memory_per_core_mib))
    if [ "$memory_cores" -lt 1 ]; then
      memory_cores=1
    fi
    if [ "$available_cores" -gt "$memory_cores" ]; then
      available_cores="$memory_cores"
    fi
  fi

  build_cores="${MACHINE_BUILD_CORES:-${NOHM_BUILD_CORES:-auto}}"
  case "$build_cores" in
  '' | auto) build_cores="$available_cores" ;;
  *[!0-9]*) build_cores="$available_cores" ;;
  esac
  if [ "$build_cores" -lt 1 ]; then
    build_cores=1
  elif [ "$build_cores" -gt "$available_cores" ]; then
    build_cores="$available_cores"
  fi

  max_jobs=$((available_cores / build_cores))
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
log_verbose "[cfg] Nix: leaving ${WRAPPER_RESERVED_CORES} machine core(s) free; build cores=${WRAPPER_BUILD_CORES}; max-jobs=${WRAPPER_MAX_JOBS}"

# Pre-switch: remove conflicting files that Home Manager will manage
rm -f "$HOME/.config/Code/User/settings.json" 2>/dev/null || true
rm -rf "$HOME/.vscode/extensions" 2>/dev/null || true
rm -f "$HOME/.local/share/applications/mimeapps.list" 2>/dev/null || true

# Step 1: Home Manager switch (always)
BEXT="${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
log_cmd "[1/2]" "home-manager switch --flake ${FLAKE_DIR}#${USERNAME}@${HOST} -b ${BEXT}"
NIX_CONFIG="${NIX_WRAPPER_CONFIG}" home-manager switch --flake "${FLAKE_DIR}#${USERNAME}@${HOST}" -b "${BEXT}"

# Step 2: NixOS or post-switch tasks
if is_nixos && ! is_home_manager_only_target; then
  log_cmd "[2/2]" "nh os switch -H ${HOST}${EXTRA_ARGS:+ ${EXTRA_ARGS}}"
  # shellcheck disable=SC2086
  NH_FLAKE="${FLAKE_DIR}" NIX_CONFIG="${NIX_WRAPPER_CONFIG}" nh os switch -H "${HOST}" $EXTRA_ARGS
elif is_nixos && is_home_manager_only_target; then
  log_verbose "[2/2] Home Manager-only target detected; skipping NixOS switch"
else
  # Non-NixOS: symlink Wayland session files for GDM visibility
  # Use ~/.local/share (home-manager managed) which has the wrapped sway path
  WAYLAND_SESSIONS_SRC="$HOME/.local/share/wayland-sessions"
  WAYLAND_SESSIONS_DST="/usr/share/wayland-sessions"
  log_cmd "[2/2]" "bash $FLAKE_DIR/scripts/setup-sway-auth.sh"
  bash "$FLAKE_DIR/scripts/setup-sway-auth.sh"

  if [ -d "$WAYLAND_SESSIONS_SRC" ]; then
    log_verbose "[2/2] Symlinking Wayland session files for GDM"
    for session in "$WAYLAND_SESSIONS_SRC"/*.desktop; do
      [ -f "$session" ] || continue
      name=$(basename "$session")
      # Resolve the symlink to get the actual nix store path (GDM can't traverse ~/...)
      resolved=$(readlink -f "$session")
      target="$WAYLAND_SESSIONS_DST/$name"
      if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$resolved" ]; then
        sudo ln -sf "$resolved" "$target"
        log_verbose "  linked: $name -> $resolved"
      else
        log_verbose "  already linked: $name"
      fi
    done
  fi
fi
