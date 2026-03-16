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

        # hm-only is a Home Manager-only target; delegate to nix-switch helper.
        if [ "''${host}" = "hm-only" ]; then
          if [ -n "''${target_host}" ]; then
            echo "nohm: --target-host is not supported for hm-only; run nix-switch on that machine." >&2
            exit 1
          fi
          exec bash "''${nix_switch_script}" "''${host}"
        fi

        nh_bin="${pkgs.nh}/bin/nh"
        hm_bin="${pkgs.home-manager}/bin/home-manager"

        # Use a unique backup extension to avoid clobbering existing *.backup files
        bext="''${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
        if [ -n "''${target_host}" ]; then
          echo "[1/2] Home Manager: skipped explicit switch (applied by NixOS activation on remote target)" >&2
        else
          echo "[1/2] Home Manager: home-manager switch --flake ''${flake_dir}#${username}@''${host} -b ''${bext}" >&2
          "$hm_bin" switch --flake "''${flake_dir}#${username}@''${host}" -b "''${bext}"
        fi

        echo "[2/2] NixOS: nh os switch -H ''${host} ''${pass_args[*]}" >&2
        NH_FLAKE="''${flake_dir}" "$nh_bin" os switch -H "''${host}" "''${pass_args[@]}"
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
