{ ... }:
{
  flake.modules.homeManager.packagesDesktop =
    { pkgs, ... }:
    {
      # Desktop applications and utilities
      home.packages = (
        with pkgs;
        [
          # Web browsers
          ungoogled-chromium

          # Communication
          vesktop
          slack
          discord
          jami

          # Media
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

          # Image tools (general)
          scrot
          ksnip
          imagemagick_light
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

          # Desktop utilities
          blueman

          # System info
          lm_sensors
          fanctl
          os-prober

          # Fonts
          font-awesome
          ibus

        ]
      );
    };
}
