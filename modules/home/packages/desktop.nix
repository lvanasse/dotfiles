# Desktop applications and utilities
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Web browsers
    ungoogled-chromium

    # Communication
    vesktop
    slack
    discord

    # Media
    jellyfin-media-player
    vlc
    spotify
    kooha

    # Office and productivity
    onlyoffice-desktopeditors
    calibre
    xournalpp
    gnome-calculator
    bitwarden-desktop
    bitwarden-menu
    libsecret

    # System utilities
    gparted
    popsicle

    # KDE applications
    kdePackages.dolphin
    kdePackages.filelight
    kdePackages.spectacle
    kdePackages.polkit-kde-agent-1
    kdePackages.xwaylandvideobridge
    kdePackages.xdg-desktop-portal-kde
    kdePackages.sddm-kcm

    # Terminal applications
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
    scrot
    wl-clipboard
    sway-contrib.grimshot
    swappy
    ksnip
    imagemagick_light
    grim
    slurp
    feh
    nitrogen

    # System tools
    wget
    libnotify # provides notify-send
    zenity
    dos2unix
    polkit
    pavucontrol
    networkmanagerapplet
    pamixer
    brightnessctl
    arandr

    # Wayland tools
    xdg-desktop-portal-wlr
    wdisplays
    swaybg
    swayidle
    swaylock
    nwg-displays
    rofi-wayland
    wofi
    mako
    blueman

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
