# Add us-intl as default keyboard layout

{ config, pkgs, ... }:
{
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  nixpkgs.config.allowUnfree = true;

  services.gnome.gnome-keyring.enable = true;

  time.hardwareClockInLocalTime = true;

  nix.settings.lazy-trees = true;

  nix.gc = {
    automatic = true; # enable periodic GC
    dates = "weekly"; # run once per week
    options = "--delete-generations +5";
  };

  nix.settings.auto-optimise-store = true;

  console.keyMap = "us-acentos";

  system.stateVersion = "25.05";

  # stylix.enable = true;
  # stylix.autoEnable = true;
  # stylix.targets.gnome.enable = false;

  ###########
  # Wayland #
  ###########

  # Display manager (SDDM) + plasma
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.sway.enable = true;

  security.polkit.enable = true;

  environment.sessionVariables = rec {
    POWERDEVIL_NO_DDCUTIL = "1";
  };

  ##########
  # Fonts #
  ##########
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
    ];
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-33.4.11"
  ];

  # Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.flatpak = {
    enable = true;
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    binutils
    elfutils
    expat
    genromfs
    picocom
    ubootTools
    utillinux
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      authorizedKeysInHomedir = true;
    };
  };

  services.printing.enable = true;
  virtualisation.docker.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
