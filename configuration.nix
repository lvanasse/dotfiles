{ config, pkgs, ... }:
{
  imports = [
    /etc/nixos/hardware-configuration.nix
  ];

  ########################
  # Boot / System basics #
  ########################
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "pc";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  nixpkgs.config.allowUnfree = true;

  services.gnome.gnome-keyring.enable = true;

  time.hardwareClockInLocalTime = true;

  nix.settings.lazy-trees = true;

  ###############
  # Fan control #
  ###############

  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  boot.kernelModules = [
    "coretemp"
    "nct6775"
  ];

  programs.coolercontrol.enable = true;

  ############
  # Network  #
  ############

  services.openvpn.servers = {
    lux = {
      config = ''
        config /home/ludovic/Downloads/lux_mtl-config_most-clients.ovpn
      '';
      autoStart = false;
    };
  };

  services.tailscale.enable = true;

  networking.enableIPv6 = false;

  ###########
  # Gaming  #
  ###########

  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.graphics.extraPackages = with pkgs; [
    mesa
    libva-utils
  ];

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;

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

  ############
  # Packages #
  ############
  environment.systemPackages = with pkgs; [
    tailscale
    fanctl
    firefox-bin
    mangohud
    protonup-qt
    lutris
    bottles
    heroic
    mesa
    nh
    kdePackages.sddm-kcm
    nixfmt-rfc-style
    zlib
    kconfig-frontends
    python3Packages.kconfiglib # For a nicer menuconfig with NuttX
    pyenv
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-gui
    coolercontrol.coolercontrol-ui-data
    coolercontrol.coolercontrol-liqctld
    # core build chain
    bison
    flex
    gettext
    texinfo
    ncurses
    vim
    git
    gperf
    automake
    autoconf
    libtool
    pkg-config
    # libs & utils
    gmp
    libmpc
    mpfr
    isl
    binutils
    elfutils
    expat
    genromfs
    picocom
    ubootTools
    utillinux
    # NuttX‑specific bits
    kconfig-frontends
    python3Packages.kconfiglib
    gcc-arm-embedded
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true; # Exports EDITOR="vim" globally
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-33.4.11"
  ];

  ########
  # Sound #
  ########
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  #################
  # System Groups #
  #################
  users.users.ludovic = {
    isNormalUser = true;
    description = "ludovic";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "input"
    ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };

  ##################
  # System Services#
  ##################
  services.printing.enable = true;
  virtualisation.docker.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";
}
