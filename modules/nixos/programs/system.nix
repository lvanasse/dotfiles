{ config, inputs, ... }:
let
  username = config.flake.lib.username;
in
{
  flake.modules.nixos.programsSystem =
    { pkgs, ... }:
    let
      # Prefer agenix from flake input; fall back if available in nixpkgs
      agenixPkg =
        if pkgs ? agenix then
          pkgs.agenix
        else
          inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
      llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
      nhOsWithHome = pkgs.writeShellScriptBin "nh-os-with-home" ''
        set -euo pipefail

        if [ $# -lt 1 ]; then
          echo "Usage: nh-os-with-home <pc|laptop> [-- <extra nh os args>]" >&2
          exit 1
        fi

        host="$1"
        shift

        # Resolve flake path regardless of current directory
        flake_dir="$HOME/Code/personal/dotfiles"
        if [ -n "''${NH_FLAKE-}" ]; then
          flake_dir="''${NH_FLAKE}"
        fi

        nh_bin="${pkgs.nh}/bin/nh"
        hm_bin="${pkgs.home-manager}/bin/home-manager"

        # Use a unique backup extension to avoid clobbering existing *.backup files
        bext="''${HM_BACKUP_EXT:-hm-$(date +%Y%m%d-%H%M%S)}"
        echo "[1/2] Home Manager: home-manager switch --flake ''${flake_dir}#${username}@''${host} -b ''${bext}" >&2
        "$hm_bin" switch --flake "''${flake_dir}#${username}@''${host}" -b "''${bext}"

        echo "[2/2] NixOS: nh os switch -H ''${host}" >&2
        NH_FLAKE="''${flake_dir}" "$nh_bin" os switch -H "''${host}" "$@"
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
        agenixPkg
        nh
        nix-du
        home-manager
        nhOsWithHome
        nixpkgs-review
        nixfmt-rfc-style
        treefmt
        llmAgents.codex
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
