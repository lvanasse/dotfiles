{ inputs, ... }:
{
  flake.modules.homeManager."packages.development" =
    { config, pkgs, ... }:
    let
      # nixpkgs patches pre-commit's hook-tmpl to `exec @pre-commit@/bin/pre-commit`,
      # baking a version-pinned store path into every hook `pre-commit install`
      # writes. That path is garbage-collected on the next nixpkgs bump, leaving
      # hooks dead ("no such file or directory"). Point the template at the
      # profile instead, which is a stable symlink across generations.
      durablePreCommit = pkgs.pre-commit.overridePythonAttrs (old: {
        # Upstream's test suite needs cargo/go/dotnet and only runs because
        # pytestCheckHook hangs off doInstallCheck; nativeCheckInputs (which
        # carry git) are gated on doCheck, so it fails before it starts.
        dontUsePytestCheck = true;
        doInstallCheck = false;

        # Rewrite in postFixup, not postPatch: fixupPhase re-runs patchShebangs
        # over the whole output and would re-pin the interpreter we just freed.
        postFixup = (old.postFixup or "") + ''
          tmpl="$out/${pkgs.python3.sitePackages}/pre_commit/resources/hook-tmpl"
          substituteInPlace "$tmpl" \
            --replace-fail "$out/bin/pre-commit" "${config.home.profileDirectory}/bin/pre-commit"
          sed -i '1s|.*|#!/usr/bin/env bash|' "$tmpl"
        '';
      });
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
      nixfmtCompat = pkgs.writeShellScriptBin "nixfmt" ''
        if [ "$#" -eq 0 ]; then
          exec ${pkgs.nixfmt}/bin/nixfmt -
        fi

        exec ${pkgs.nixfmt}/bin/nixfmt "$@"
      '';
      clangDriverBins = pkgs.runCommandLocal "clang-driver-bins" { } ''
        mkdir -p "$out/bin"
        ln -s ${pkgs.clang}/bin/clang "$out/bin/clang"
        ln -s ${pkgs.clang}/bin/clang++ "$out/bin/clang++"
      '';
      # Make a devcontainer's compile_commands.json usable by host clangd:
      # rewrites /workspaces/<repo> paths to the host worktree so go-to-definition
      # works without the container running. Re-run after each in-container build.
      clangdRehost = pkgs.writeShellScriptBin "clangd-rehost" ''
        exec ${pkgs.python3}/bin/python3 ${./clangd-rehost.py} "$@"
      '';
    in
    {
      # Global clangd config: makes navigation usable in repos without a
      # compile_commands.json (e.g. a freshly cloned PR). Relative -I paths
      # resolve against the file's directory in fallback mode, so these cover
      # common src/ + include/ layouts; missing dirs are silently ignored.
      xdg.configFile."clangd/config.yaml".text = ''
        CompileFlags:
          Add: [-I., -I.., -Iinclude, -I../include, -I../../include]
        ---
        # Forces C++20 on C++ sources, overriding a project's own -std. Not
        # C++23: clang 21 segfaults on libstdc++ <expected> when third-party
        # headers are unresolved, which is the norm in fallback mode. Plain
        # .h files are left alone since they may be C headers.
        If:
          PathMatch: .*\.(cpp|cc|cxx|c\+\+|hpp|hh|hxx|ipp|tpp)
        CompileFlags:
          Remove: [-std=*]
          Add: [-std=c++20]
      '';

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
          clangDriverBins
          clang-tools
          basedpyright
          python3
          ruff
          uv
          bash-language-server
          bitbake-language-server
          taplo
          lua-language-server
          vscode-langservers-extracted
          yaml-language-server
          cmake-language-server
          dockerfile-language-server
          marksman
          actionlint
          shellcheck
          shfmt
          yamllint
          buf # Protobuf toolchain: parse, lint, format (language server for vscode-buf)
          bear
          meson
          ninja

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
          nixfmtCompat
          clangdRehost

          # Libraries
          ncurses
          zlib

          jq
          cachix

          # Hardware tools
          saleae-logic-2

          pyenv
          durablePreCommit

          # Networking
          wireshark
          fenix.packages.rust-analyzer
          fenix.toolchain

          saleae-logic-2

        ])
        ++ [
          tex # TeX toolchain for LaTeX preview/build
        ];
    };
}
