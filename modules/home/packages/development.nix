# Development packages
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    # Development tools
    sonarlint-ls
    devenv
    direnv
    git
    rustup
    nodejs
    (inputs."nixpkgs-unstable".legacyPackages.${pkgs.system}.codex)
    home-manager
    fish # Fish shell for testing
    zsh # Zsh shell
    oh-my-zsh # Manual oh-my-zsh installation
    starship # Cross-shell prompt

    # Build tools
    gnumake
    gcc
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

    # Embedded development
    gcc-arm-embedded
    genromfs
    kconfig-frontends
    python3Packages.kconfiglib # For a nicer menuconfig with NuttX

    # System tools
    lshw
    dmidecode
    usbutils

    # Nix tools
    nixfmt-rfc-style

    # Libraries
    ncurses
    zlib

    # Version control
    jq

    # Hardware tools
    saleae-logic-2

    # Python environment
    pyenv
  ];
}
