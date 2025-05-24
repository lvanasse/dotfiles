# # TODO A way to store the gnome-terminal profile
# # TODO fix zsh not showing git status -> it's source $ZSH/oh-my-zsh.sh that was not called
# # TODO fix git to use lvanasse instead of random user
# # TODO Add sway config
{ config, pkgs, ... }:
{
  home.username = "ludovic";
  home.homeDirectory = "/home/ludovic";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  ######################################
  # Wayland user-level config
  ######################################
  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      input = {
        "*" = {
          xkb_layout = "us";
          xkb_variant = "intl";
        };
      };
      terminal = "gnome-terminal";
      menu = "bemenu-run -p \"\"";
      bars = [ ];
    };
    extraConfig = "
        include ~/.config/sway/outputs
        include ~/.config/sway/workspaces
      ";
  };

  programs.bemenu.enable = true;

  ######################################
  # Shell & Git user-level config
  ######################################
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
  };

  programs.git = {
    enable = true;
    userName = "Ludovic Vanasse";
    userEmail = "lvanasse@luxaerobot.com";
  };

  ######################################
  # Emacs user-level config
  ######################################
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
    flake = "/home/ludovic/Code/dotfiles";
  };

  ######################################
  # Programs config
  ######################################

  ######################################
  # Personal user packages
  ######################################
  home.packages = with pkgs; [
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
    sway
    wl-clipboard
    # mako
    waybar
    gnome-terminal
    # firefox
    slack
    discord
    spotify
    bitwarden-desktop
    vim
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
    openvpn3
    openvpn
    netdiscover
    wezterm
    alacritty
    lshw
    dmidecode
    home-manager
    gnome-terminal
    ungoogled-chromium
    wofi
    bemenu
    calibre
    docker
    kdePackages.filelight
    kdePackages.spectacle
    kdePackages.polkit-kde-agent-1
    kdePackages.xwaylandvideobridge
    kdePackages.xdg-desktop-portal-kde
    kdePackages.sddm-kcm
    libreoffice
    openvpn3
    docker
    retroarch
    element-desktop
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        jdinhlife.gruvbox
        jnoortheen.nix-ide
        rust-lang.rust-analyzer
        ms-vscode.cpptools-extension-pack
        twxs.cmake
        ms-vscode.cpptools
        ms-vscode.cmake-tools
        ms-vscode.makefile-tools
        vadimcn.vscode-lldb
        streetsidesoftware.code-spell-checker
        foxundermoon.shell-format
      ];
    })

  ];

}
