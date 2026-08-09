{ ... }:
{
  flake.modules.homeManager."packages.desktop" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      koreaderEnglishDictionary = pkgs.fetchzip {
        url = "https://www.reader-dict.com/file/en/dict-en-en-noetym.zip";
        hash = "sha256-k0J/PwEt00I+XTzBLPeQm2HNjDXbeFk2Hc4QEPTxi0A=";
        stripRoot = false;
      };

      koreaderCwaSyncPlugin = pkgs.fetchzip {
        url = "https://cwa.ludovicvanasse.com/static/koplugin.zip";
        hash = "sha256-YCUKOtvmtP13uoBO/MRH/SG+4kkTHDfOcHEg7cBgGC8=";
      };

      koreaderAnnotationSyncPlugin = pkgs.fetchzip {
        url = "https://github.com/dani84bs/AnnotationSync.koplugin/archive/refs/tags/v1.0.zip";
        hash = "sha256-gpI8EJRga2Z6HVWCDMAzGqLAHrqhRf4Q2iI43scoHAE=";
      };

      qbzVersion = "2.0.2";
      qbzAppImage = pkgs.fetchurl {
        url = "https://github.com/vicrodh/qbz/releases/download/v${qbzVersion}/QBZ_${qbzVersion}_amd64.AppImage";
        hash = "sha256-Kz3EEbP2tCm4oRXvMYUlnUQn6hjZRG2mQvQzQDhXj9U=";
      };
      qbzExtracted = pkgs.appimageTools.extractType2 {
        pname = "qbz";
        version = qbzVersion;
        src = qbzAppImage;
      };
      qbz = pkgs.appimageTools.wrapType2 {
        pname = "qbz";
        version = qbzVersion;
        src = qbzAppImage;
      };

      koreaderDictDir = "${config.home.homeDirectory}/.config/koreader/data/dict";
    in
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
          qbz
          kooha
          simplescreenrecorder

          # Office and productivity
          onlyoffice-desktopeditors
          calibre
          koreader
          evince
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

          # Text helpers
          (aspellWithDicts (
            dicts: with dicts; [
              en
              fr
            ]
          ))

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
          emacs-all-the-icons-fonts
          font-awesome
          ibus

        ]
      );

      home.file.".local/share/applications/qbz.desktop".text = ''
        [Desktop Entry]
        Name=QBZ
        Comment=Native Qobuz client with hi-res audio support
        Exec=${qbz}/bin/qbz %u
        Icon=${qbzExtracted}/qbz.png
        Terminal=false
        Type=Application
        Categories=AudioVideo;Audio;Music;Player;
        Keywords=music;audio;qobuz;hifi;streaming;audiophile;flac;
        StartupWMClass=com.blitzfc.qbz
        StartupNotify=true
        MimeType=x-scheme-handler/qobuzapp;
      '';

      home.activation.koreaderEnglishDictionary = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        dict_dir="${koreaderDictDir}"
        res_dir="$dict_dir/res"

        ${pkgs.coreutils}/bin/mkdir -p "$res_dir"

        ${pkgs.coreutils}/bin/install -m644 -T "${koreaderEnglishDictionary}/dict-data.ifo" \
          "$dict_dir/reader-dict-en-en-noetym.ifo"
        ${pkgs.coreutils}/bin/install -m644 -T "${koreaderEnglishDictionary}/dict-data.idx" \
          "$dict_dir/reader-dict-en-en-noetym.idx"
        ${pkgs.coreutils}/bin/install -m644 -T "${koreaderEnglishDictionary}/dict-data.dict.dz" \
          "$dict_dir/reader-dict-en-en-noetym.dict.dz"
        ${pkgs.coreutils}/bin/install -m644 -T "${koreaderEnglishDictionary}/dict-data.syn" \
          "$dict_dir/reader-dict-en-en-noetym.syn"

        if [ -d "${koreaderEnglishDictionary}/res" ]; then
          ${pkgs.coreutils}/bin/cp -fR "${koreaderEnglishDictionary}/res/." "$res_dir/"
        fi
      '';

      home.file.".config/koreader/plugins/cwasync.koplugin" = {
        source = koreaderCwaSyncPlugin;
        recursive = true;
      };

      home.file.".config/koreader/plugins/AnnotationSync.koplugin" = {
        source = koreaderAnnotationSyncPlugin;
        recursive = true;
      };
    };
}
