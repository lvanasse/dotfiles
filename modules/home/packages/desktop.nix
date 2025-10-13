# Desktop applications and utilities
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Web browsers
    firefox
    ungoogled-chromium

    # Communication
    vesktop
    slack
    discord

    # Media
    jellyfin-media-player
    vlc
    spotify

    # Office and productivity
    onlyoffice-desktopeditors
    calibre
    xournalpp
    gnome-calculator
    bitwarden-desktop
    bitwarden-menu

    # System utilities
    gparted
    popsicle

    # KDE applications
    kdePackages.filelight
    kdePackages.spectacle
    kdePackages.polkit-kde-agent-1
    kdePackages.xwaylandvideobridge
    kdePackages.xdg-desktop-portal-kde
    kdePackages.sddm-kcm

    # Terminal applications
    gnome-terminal
    wezterm
    alacritty
    foot

    # System monitoring
    htop
    btop
    nvtopPackages.full
    screenfetch

    # Network tools
    netcat-gnu
    netdiscover
    openvpn3

    # File management
    tree
    p7zip
    unzip
    unrar

    # Image tools
    flameshot
    scrot
    imagemagick_light
    grim
    slurp
    feh
    nitrogen

    # System tools
    wget
    zenity
    dos2unix
    polkit
    pavucontrol
    networkmanagerapplet
    arandr

    # Wayland tools
    xdg-desktop-portal-wlr
    wdisplays
    swaybg
    swayidle
    nwg-displays
    rofi
    wofi

    # System info
    lm_sensors
    fanctl
    os-prober

    # Fonts
    font-awesome
    ibus

    # Themes for Plasma theming
    tela-icon-theme
    whitesur-cursors
  ];
}
