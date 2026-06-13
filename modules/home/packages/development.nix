{ inputs, ... }:
{
  flake.modules.homeManager."packages.development" =
    { pkgs, ... }:
    let
      fenix = {
        packages = inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system};
        latest = inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.latest;
        toolchain = inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.latest.withComponents [
          "cargo"
          "clippy"
          "rust-src"
          "rustc"
          "rustfmt"
        ];
      };
      # Minimal but capable TeX Live for LaTeX Workshop (PDF build + bib + fonts)
      tex = pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-small
          latexmk
          xetex
          biber
          collection-bibtexextra
          collection-fontsrecommended
          collection-latexextra
          ;
      };
    in
    {
      # Development packages
      home.packages =
        (with pkgs; [
          # Development tools
          sonarlint-ls # CLI language server companion for SonarLint 4.37.0
          unstable.devenv
          direnv
          nodejs
          home-manager
          fish # Fish shell
          starship # Cross-shell prompt
          nil
          nixd
          act
          unstable.vscode
          clang-tools
          basedpyright
          python3
          bash-language-server
          yaml-language-server
          cmake-language-server
          dockerfile-language-server
          marksman
          actionlint
          shellcheck
          shfmt
          yamllint
          bear

          # Build tools
          gnumake
          gcc
          binutils
          cmake
          automake
          autoconf
          libtool
          pkg-config
          bison
          flex
          gettext
          texinfo
          gperf
          diffutils

          # Embedded development
          gcc-arm-embedded
          genromfs
          kconfig-frontends
          python3Packages.kconfiglib # For a nicer menuconfig with NuttX

          # System tools
          lshw
          dmidecode
          usbutils
          gnugrep
          gnupg
          git-lfs
          gh
          vim
          curl
          (devcontainer.override { docker = docker_29; })

          # Nix tools
          nixfmt-rfc-style

          # Libraries
          ncurses
          zlib

          jq
          cachix

          # Hardware tools
          saleae-logic-2

          pyenv
          pre-commit

          # Networking
          wireshark
          fenix.packages.rust-analyzer
          fenix.toolchain
        ])
        ++ [
          tex # TeX toolchain for LaTeX preview/build
        ];
    };
}
