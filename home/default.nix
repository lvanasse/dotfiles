# # TODO A way to store the gnome-terminal profile
# # TODO fix zsh not showing git status -> it's source $ZSH/oh-my-zsh.sh that was not called
# # TODO fix git to use lvanasse instead of random user
# # TODO Add sway config
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.enableNixpkgsReleaseCheck = false;

  nixpkgs.config.allowUnfree = true;

  home.username = "ludovic";
  home.homeDirectory = "/home/ludovic";
  home.stateVersion = "25.05";

  home.sessionVariables = {
        NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";

  };

  #############################
  # Wayland user-level config #
  #############################
  # wayland.windowManager.sway = {
  #   enable = true;
  #   systemd.enable = true; # creates sway‑session.target
  #   config = rec {
  #     modifier = "Mod4";
  #     input = {
  #       "*" = {
  #         xkb_layout = "us";
  #         xkb_variant = "intl";
  #       };
  #     };
  #     terminal = "gnome-terminal";
  #     menu = "bemenu-run -p \"\"";
  #     bars = [ ];
  #   };
  #   extraConfig = "
  #       include ~/.config/sway/outputs
  #       include ~/.config/sway/workspaces
  #     ";
  # };

  ###################
  # Programs config #
  ###################

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "minimal";
      plugins = [
        "git"
        "sudo"
        "docker"
      ];
    };
    initExtra = ''
      # for npm global installs
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
  };

  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [
      epkgs.gruvbox-theme
    ];
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${config.home.homeDirectory}/Code/personal/dotfiles";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # stylix.enable = true;
  # stylix.autoEnable = true;
  # stylix.targets.gnome.enable = false;

  # stylix.image = ../wallpapers/1458678242783.jpg;
  # stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

  # stylix.fonts = {
  #   emoji = {
  #     package = pkgs.noto-fonts-emoji-blob-bin;
  #     name = "Noto Emoji with extended Blob support";
  #   };
  # };

  # services.mako.enable = false;

  # systemd.user.services.mako = {
  #   Unit = {
  #     Description = "Mako notification daemon (Wayland WMs only)";
  #     PartOf = [
  #       "sway-session.target"
  #     ];
  #     # stop automatically when you switch back to KDE
  #     StopWhenUnneeded = true;
  #   };

  #   Service = {
  #     ExecStart = "${pkgs.mako}/bin/mako";
  #     Restart = "on-failure";
  #     Environment = "XDG_CURRENT_DESKTOP=wayland"; # harmless fallback
  #   };

  #   Install = {
  #     WantedBy = [
  #       "sway-session.target"
  #     ];
  #   };
  # };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.extensions = with pkgs.vscode-marketplace; [
      codium.codium
      bbenoist.nix
      jdinhlife.gruvbox
      jnoortheen.nix-ide
      rust-lang.rust-analyzer
      ms-vscode.cpptools-extension-pack
      ms-vscode.cpptools
      ms-vscode.cmake-tools
      ms-vscode.makefile-tools
      # vadimcn.vscode-lldb
      streetsidesoftware.code-spell-checker
      foxundermoon.shell-format
      vscode-icons-team.vscode-icons
      sonarsource.sonarlint-vscode
      jeff-hykin.better-c-syntax
      marus25.cortex-debug
      mcu-debug.memory-view
      mcu-debug.rtos-views
      mcu-debug.peripheral-viewer
      redhat.vscode-yaml
      jeff-hykin.better-cpp-syntax
      mkhl.direnv
      microhobby.linuxkerneldev
    ];
  };

  ##########################
  # Personal user packages #
  ##########################
  home.packages = with pkgs; [
    screenfetch
    jq
    saleae-logic-2
    devenv
    direnv
    netcat-gnu
    htop
    firefox
    lm_sensors
    fanctl
    gcc-arm-embedded
    genromfs
    gnome-calculator
    vesktop
    jellyfin-media-player
    gparted
    vlc
    wine
    winetricks
    mono
    gnugrep
    wget
    zenity
    grim
    p7zip
    unzip
    unrar
    qbittorrent
    gamescope
    gamemode
    btop
    nvtopPackages.full
    gnome-terminal
    slack
    discord
    spotify
    bitwarden-desktop
    wget
    tree
    git
    zsh
    oh-my-zsh
    rustup
    feh
    arandr
    pavucontrol
    networkmanagerapplet
    polkit
    nixpkgs-fmt
    flameshot
    scrot
    imagemagick_light
    nitrogen
    spotify
    bitwarden-desktop
    bitwarden-menu
    discord
    slack
    moserial
    putty
    docker
    gnumake
    gcc
    ibus
    font-awesome
    kicad-small
    freecad
    xournalpp
    rofi
    cmake
    bash
    dos2unix
    xdg-desktop-portal-wlr
    os-prober
    wdisplays
    swaybg
    swayidle
    foot
    nwg-displays
    grim
    slurp
    netdiscover
    wezterm
    alacritty
    nodejs
    lshw
    dmidecode
    home-manager
    gnome-terminal
    ungoogled-chromium
    calibre
    docker
    popsicle
    kdePackages.filelight
    kdePackages.spectacle
    kdePackages.polkit-kde-agent-1
    kdePackages.xwaylandvideobridge
    kdePackages.xdg-desktop-portal-kde
    kdePackages.sddm-kcm
    onlyoffice-desktopeditors
    openvpn3
    bison
    flex
    gettext
    texinfo
    ncurses
    git
    gperf
    automake
    autoconf
    libtool
    pkg-config
    usbutils
    bison
    flex
    gettext
    texinfo
    ncurses
    git
    gperf
    automake
    autoconf
    libtool
    pkg-config
    tailscale
    nixfmt-rfc-style
    zlib
    gcc-arm-embedded
    kconfig-frontends
    python3Packages.kconfiglib # For a nicer menuconfig with NuttX
    pyenv
    xemu
    jre_minimal
    pcsx2
    (retroarch.withCores (
      cores: with cores; [
        snes9x # Super NES
        mupen64plus # Nintendo 64
        genesis-plus-gx # Mega Drive / SMS / GG
        pcsx2 # PlayStation 2
        dolphin # GameCube / Wii
      ]
    ))
    retroarch-assets
  ];

}
