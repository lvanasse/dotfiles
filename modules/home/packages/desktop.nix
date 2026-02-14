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
          google-chrome

          # Communication
          vesktop
          slack
          discord
          jami

          # Media
          vlc
          spotify
          kooha
          simplescreenrecorder

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
          firmware-updater
          gnome-software

          # Terminal applications (wezterm installed via programs.wezterm)
          alacritty
          foot

          # System monitoring
          htop
          btop
          nvtopPackages.full
          screenfetch
          nload

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
          efibootmgr
          btrfs-progs
          pciutils

          # Desktop utilities
          blueman

          # System info
          lm_sensors
          fanctl
          os-prober

          # Fonts
          font-awesome
          kdePackages.breeze-icons
          ibus

        ]
      );
    };
}
