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
    home-manager
    
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
    
    # Java
    jre_minimal
    
    # Python environment
    pyenv
  ];
}