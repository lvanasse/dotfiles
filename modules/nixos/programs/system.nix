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

        if [ $# -lt 1 ]; then
          echo "Usage: nohm <host> [--target-host <user@ip>] [-- <extra nh os args>]" >&2
          exit 1
        fi

        host="$1"
        shift

        target_host=""
        pass_args=()
        while [ $# -gt 0 ]; do
          case "$1" in
            --target-host)
              if [ $# -lt 2 ]; then
                echo "Missing value for --target-host" >&2
                exit 1
              fi
              target_host="$2"
              pass_args+=("$1" "$2")
              shift 2
              ;;
            --)
              pass_args+=("$@")
              break
              ;;
            *)
              pass_args+=("$1")
              shift
              ;;
          esac
        done

        # Resolve flake path regardless of current directory
        flake_dir="$HOME/Code/personal/dotfiles"
        if [ -n "''${NH_FLAKE-}" ]; then
          flake_dir="''${NH_FLAKE}"
        fi
        nix_switch_script="''${flake_dir}/scripts/nix-switch.sh"

        nh_bin="${pkgs.nh}/bin/nh"
        hm_bin="${pkgs.home-manager}/bin/home-manager"
        git_bin="${pkgs.git}/bin/git"
        nproc_bin="${pkgs.coreutils}/bin/nproc"

        reserve_cores="''${MACHINE_RESERVED_CORES:-''${NOHM_RESERVED_CORES:-1}}"
        case "''${reserve_cores}" in
          ""|*[!0-9]*) reserve_cores=1 ;;
        esac

        build_cores="''${NOHM_BUILD_CORES:-1}"
        case "''${build_cores}" in
          ""|*[!0-9]*) build_cores=1 ;;
        esac

        total_cores="$("$nproc_bin")"
        case "''${total_cores}" in
          ""|*[!0-9]*) total_cores=1 ;;
        esac

        max_jobs=$(( total_cores - reserve_cores ))
        if [ "''${max_jobs}" -lt 1 ]; then
          max_jobs=1
        fi

        nix_config=$(printf 'max-jobs = %s\ncores = %s' "''${max_jobs}" "''${build_cores}")
        if [ -n "''${NIX_CONFIG-}" ]; then
          nix_config="''${nix_config}
''${NIX_CONFIG}"
        fi
        echo "[cfg] Nix: leaving ''${reserve_cores} machine core(s) free; max-jobs=''${max_jobs}; cores=''${build_cores}" >&2

        # hm-only is a Home Manager-only target; delegate to nix-switch helper.
        if [ "''${host}" = "hm-only" ]; then
          if [ -n "''${target_host}" ]; then
            echo "nohm: --target-host is not supported for hm-only; run nix-switch on that machine." >&2
            exit 1
          fi
          exec bash "''${nix_switch_script}" "''${host}"
        fi

        # Git flakes ignore untracked files. Mark untracked paths as intent-to-add
        # so newly created modules are visible during flake evaluation.
        if [ "''${NOHM_AUTO_INTENT_TO_ADD:-1}" = "1" ] \
          && "$git_bin" -C "''${flake_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          did_ita=""
          while IFS= read -r -d $'\0' path; do
            if [ -z "''${did_ita}" ]; then
              echo "[pre] Git: marking untracked files as intent-to-add for flake evaluation" >&2
              did_ita="1"
            fi
            "$git_bin" -C "''${flake_dir}" add -N -- "$path"
          done < <("$git_bin" -C "''${flake_dir}" ls-files --others --exclude-standard -z)
        fi

        # Use a unique backup extension to avoid clobbering existing *.backup files
        bext="''${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
        if [ -n "''${target_host}" ]; then
          echo "[1/2] Home Manager: skipped explicit switch (applied by NixOS activation on remote target)" >&2
        else
          echo "[1/2] Home Manager: home-manager switch --flake ''${flake_dir}#${username}@''${host} -b ''${bext}" >&2
          NIX_CONFIG="''${nix_config}" "$hm_bin" switch --flake "''${flake_dir}#${username}@''${host}" -b "''${bext}"
        fi

        echo "[2/2] NixOS: nh os switch -H ''${host} ''${pass_args[*]}" >&2
        NH_FLAKE="''${flake_dir}" NIX_CONFIG="''${nix_config}" "$nh_bin" os switch -H "''${host}" "''${pass_args[@]}"
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
        unstable.codex
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
