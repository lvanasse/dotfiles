{ config, ... }:
let
  username = config.flake.lib.username;
in
{
  flake.modules.nixos."programs.system" =
    { pkgs, ... }:
    let
      nohm = pkgs.writeShellScriptBin "nohm" ''
                set -euo pipefail

                # --- Logging helpers ---
                green=$'\033[32m'
                red=$'\033[31m'
                dim=$'\033[2m'
                reset=$'\033[0m'

                step() { printf '❯ %s\n' "$1" >&2; }
                cmd()  { printf '  %s$ %s%s\n' "''${dim}" "$1" "''${reset}" >&2; }
                ok()   { printf '%s✓%s %s\n' "''${green}" "''${reset}" "$1" >&2; }
                fail() { printf '%s✗%s %s\n' "''${red}" "''${reset}" "$1" >&2; }

                # Filter known nix noise from combined output
                filter_noise() {
                  grep -v "^Using saved setting\|^warning: Git tree\|^warning:.*builtins.derivation" || true
                }

                # --- Argument parsing ---
                if [ $# -lt 1 ]; then
                  echo "Usage: nohm <host>|auth [--target-host <user@ip>] [-- <extra nh args>]" >&2
                  exit 1
                fi

                host="$1"
                shift

                target_host=""
                extra_args=()
                while [ $# -gt 0 ]; do
                  case "$1" in
                    --target-host)
                      [ $# -lt 2 ] && { echo "Missing value for --target-host" >&2; exit 1; }
                      target_host="$2"
                      shift 2
                      ;;
                    --)
                      shift
                      extra_args+=("$@")
                      break
                      ;;
                    *)
                      extra_args+=("$1")
                      shift
                      ;;
                  esac
                done

                # --- Resolve paths ---
                flake_dir="$HOME/Code/personal/dotfiles"
                if [ -n "''${NH_FLAKE-}" ]; then
                  flake_dir="''${NH_FLAKE}"
                fi

                if [ "''${host}" = "auth" ]; then
                  exec bash "''${flake_dir}/scripts/setup-sway-auth.sh"
                fi

                is_home_manager_only_target() {
                  case "''${host}" in
                    hm-only|work-laptop|steamdeck) return 0 ;;
                    *) return 1 ;;
                  esac
                }

                if is_home_manager_only_target; then
                  if [ -n "''${target_host}" ]; then
                    echo "nohm: --target-host is not supported for Home Manager-only targets; run nohm on that machine." >&2
                    exit 1
                  fi
                  exec bash "''${flake_dir}/scripts/nix-switch.sh" "''${host}"
                fi

                # --- Tool paths ---
                nh_bin="${pkgs.nh}/bin/nh"
                hm_bin="${pkgs.home-manager}/bin/home-manager"
                git_bin="${pkgs.git}/bin/git"
                nproc_bin="${pkgs.coreutils}/bin/nproc"
                nix_bin="${pkgs.nix}/bin/nix"
                ssh_bin="${pkgs.openssh}/bin/ssh"

                # --- Compute parallelism ---
                reserve_cores="''${NOHM_RESERVED_CORES:-2}"
                case "''${reserve_cores}" in ""|*[!0-9]*) reserve_cores=2 ;; esac
                total_cores="$("$nproc_bin")"
                available_cores=$(( total_cores - reserve_cores ))
                [ "''${available_cores}" -lt 1 ] && available_cores=1

                build_cores="''${NOHM_BUILD_CORES:-auto}"
                case "''${build_cores}" in ""|auto|*[!0-9]*) build_cores="''${available_cores}" ;; esac
                [ "''${build_cores}" -lt 1 ] && build_cores=1
                [ "''${build_cores}" -gt "''${available_cores}" ] && build_cores="''${available_cores}"

                max_jobs=$(( available_cores / build_cores ))
                [ "''${max_jobs}" -lt 1 ] && max_jobs=1

                nix_config=$(printf 'max-jobs = %s\ncores = %s\nwarn-dirty = false\naccept-flake-config = true' "''${max_jobs}" "''${build_cores}")
                [ -n "''${NIX_CONFIG-}" ] && nix_config="''${nix_config}
        ''${NIX_CONFIG}"

                # --- Git: mark untracked files for flake evaluation ---
                if [ "''${NOHM_AUTO_INTENT_TO_ADD:-1}" = "1" ] \
                  && "$git_bin" -C "''${flake_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                  while IFS= read -r -d $'\0' path; do
                    "$git_bin" -C "''${flake_dir}" add -N -- "$path"
                  done < <("$git_bin" -C "''${flake_dir}" ls-files --others --exclude-standard -z)
                fi

                # --- Determine steps ---
                is_remote() { [ -n "''${target_host}" ]; }
                should_validate_spacemacs() {
                  case "''${host}" in pc|laptop|hm-only) return 0 ;; *) return 1 ;; esac
                }

                # --- Step: Home Manager (local only) ---
                if ! is_remote; then
                  step "Home Manager switch (''${host})"
                  cmd "home-manager switch --flake .#${username}@''${host}"
                  bext="''${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
                  if env NIX_CONFIG="''${nix_config}" "$hm_bin" switch \
                    --flake "''${flake_dir}#${username}@''${host}" -b "''${bext}" 2>&1 | filter_noise; then
                    ok "Home Manager"
                  else
                    fail "Home Manager"
                    exit 1
                  fi
                fi

                # --- Step: NixOS switch ---
                if is_remote; then
                  out_link="$(mktemp -d)/result"

                  step "Build NixOS configuration (''${host}) [''${build_cores} cores, ''${max_jobs} jobs]"
                  cmd "nh os build -H ''${host}"
                  if env NH_FLAKE="''${flake_dir}" NIX_CONFIG="''${nix_config}" \
                    "$nh_bin" os build -H "''${host}" -o "''${out_link}" "''${extra_args[@]}"; then
                    ok "Build"
                  else
                    fail "Build"
                    exit 1
                  fi

                  system_path="$(readlink -f "''${out_link}")"

                  step "Copy closure → ''${target_host}"
                  cmd "nix copy --to ssh://''${target_host}"
                  if "$nix_bin" copy --log-format bar --to "ssh://''${target_host}" "''${system_path}"; then
                    ok "Copy"
                  else
                    fail "Copy"
                    exit 1
                  fi

                  step "Activate on ''${target_host}"
                  cmd "switch-to-configuration switch"
                  if "$ssh_bin" -t "''${target_host}" \
                    "sudo nix-env --profile /nix/var/nix/profiles/system --set ''${system_path} && sudo ''${system_path}/bin/switch-to-configuration switch"; then
                    ok "Activate"
                  else
                    fail "Activate"
                    exit 1
                  fi

                  rm -rf "$(dirname "''${out_link}")"
                elif is_home_manager_only_target; then
                  step "Home Manager-only target (''${host})"
                  ok "Skipped NixOS switch"
                else
                  step "NixOS switch (''${host}) [''${build_cores} cores, ''${max_jobs} jobs]"
                  cmd "nh os switch -H ''${host}"
                  if env NH_FLAKE="''${flake_dir}" NIX_CONFIG="''${nix_config}" \
                    "$nh_bin" os switch -H "''${host}" "''${extra_args[@]}"; then
                    ok "NixOS"
                  else
                    fail "NixOS"
                    exit 1
                  fi
                fi
      '';

      nhOsWithHomeCompat = pkgs.writeShellScriptBin "nh-os-with-home" ''
        exec ${nohm}/bin/nohm "$@"
      '';
    in
    {
      # System packages
      environment.systemPackages = with pkgs; [
        vim
        binutils
        elfutils
        expat
        genromfs
        picocom
        ubootTools
        util-linux
        ripgrep
        rsync
        pavucontrol
        openssh
        agenix
        tailscale
        nh
        nix-du
        home-manager
        nohm
        nhOsWithHomeCompat
        nixpkgs-review
        nixfmt-rfc-style
        treefmt
        pkgs.llm-agents.codex
        pkgs.llm-agents.claude-code
        gh
        act
      ];

      # System programs
      programs.vim = {
        enable = true;
        defaultEditor = true;
      };

      # Disable legacy command-not-found (uses channels DB and is noisy)
      programs.command-not-found.enable = false;

      # Enable nix-ld for running dynamically linked binaries.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # Common libraries needed by dynamically linked binaries
          stdenv.cc.cc.lib
          zlib
          openssl
          curl
          glib
          glibc
          xorg.libX11
          xorg.libXcursor
          xorg.libXrandr
          xorg.libXi
          libGL
        ];
      };

      programs.java = {
        enable = true;
        package = pkgs.openjdk21;
      };

      # Electron apps like Bitwarden expect a working SUID sandbox.
      security.chromiumSuidSandbox.enable = true;
      environment.sessionVariables.CHROME_DEVEL_SANDBOX = "/run/wrappers/bin/chrome-sandbox";
    };
}
