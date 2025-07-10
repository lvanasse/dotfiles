# { config, pkgs, ... }:
# {
  # imports = [
  #   ./hardware-configuration.nix
  # ];

  ########################
  # Boot / System basics #
  ########################
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "nodev";
  # boot.loader.grub.useOSProber = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "pc";
  # networking.networkmanager.enable = true;

  # time.timeZone = "America/Toronto";
  # i18n.defaultLocale = "en_CA.UTF-8";

  # nixpkgs.config.allowUnfree = true;

  # services.gnome.gnome-keyring.enable = true;

  # time.hardwareClockInLocalTime = true;

  # nix.settings.lazy-trees = true;

  # nix.gc = {
  #   automatic = true; # enable periodic GC
  #   dates = "weekly"; # run once per week
  #   options = "--delete-generations +5";
  # };

  # nix.settings.auto-optimise-store = true;

  ###############
  # Fan control #
  ###############

  # boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  # boot.kernelModules = [
  #   "coretemp"
  #   "nct6775"
  # ];

  # programs.coolercontrol.enable = true;

  ############
  # Network  #
  ############

  # services.openvpn.servers = {
  #   lux = {
  #     config = ''
  #       config /home/ludovic/Downloads/lux_mtl-config_most-clients.ovpn
  #     '';
  #     autoStart = false;
  #   };
  # };

  # services.tailscale.enable = false;

  # networking.enableIPv6 = false;

  # networking.useNetworkd = true;
  # networking.interfaces.enp5s0.useDHCP = true;

  # # Specifically for MAM private tracker
  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 59793 ];
  # };

  # # Fix DNS latency issues
  # services.resolved = {
  #   enable = true;
  #   dnssec = "false";
  #   fallbackDns = [
  #     "1.1.1.1"
  #     "9.9.9.9"
  #   ];
  #   extraConfig = ''
  #     Cache=no-negative                  # avoid long NXDOMAIN waits
  #     TrustAnchor=false                  # strips the “trust-ad” bit
  #   '';
  # };
  # networking.networkmanager.dns = "systemd-resolved";

  ###########
  # Gaming  #
  ###########

  # boot.initrd.kernelModules = [ "amdgpu" ];

  # hardware.graphics = {
  #   enable = true;
  #   enable32Bit = true;
  # };

  # hardware.graphics.extraPackages = with pkgs; [
  #   mesa
  #   libva-utils
  # ];

  # programs.steam.enable = true;
  # programs.steam.gamescopeSession.enable = true;
  # programs.gamemode.enable = true;

  # # Torrent
  # systemd.user.services.qbittorrent-tray = {
  #   description = "qBittorrent (GUI, tray only)";
  #   wantedBy = [ "graphical-session.target" ];
  #   after = [ "graphical-session.target" ];

  #   serviceConfig = {
  #     ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent --no-splash";
  #     Restart = "on-abort";
  #   };
  # };

  # ###########
  # # Wayland #
  # ###########

  # # Display manager (SDDM) + plasma
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;
  # services.desktopManager.plasma6.enable = true;

  # programs.sway.enable = true;

  # security.polkit.enable = true;

  # environment.sessionVariables = rec {
  #   POWERDEVIL_NO_DDCUTIL = "1";
  # };

  # ##########
  # # Fonts #
  # ##########
  # fonts = {
  #   fontDir.enable = true;
  #   packages = with pkgs; [
  #     noto-fonts
  #     noto-fonts-cjk-sans
  #     noto-fonts-emoji
  #     liberation_ttf
  #     fira-code
  #     fira-code-symbols
  #     mplus-outline-fonts.githubRelease
  #     dina-font
  #     proggyfonts
  #     nerd-fonts.fira-code
  #     nerd-fonts.droid-sans-mono
  #   ];
  # };

  ############
  # Packages #
  ############

  # 1 = system
  # 2 = pc / laptop
  # 3 = hm
  environment.systemPackages = with pkgs; [
    # tailscale 3
    # fanctl 1
    # mangohud 1
    # lutris 1
    # bottles 1
    # heroic 1
    # mesa 1
    # nh 1
    # kdePackages.sddm-kcm 1
    # nixfmt-rfc-style 1
    # zlib 1
    # kconfig-frontends 3
    # python3Packages.kconfiglib 3  # For a nicer menuconfig with NuttX
    # pyenv 3
    # coolercontrol.coolercontrold 2
    # coolercontrol.coolercontrol-gui 2
    # coolercontrol.coolercontrol-ui-data 2
    # coolercontrol.coolercontrol-liqctld 2
    # core build chain
    # bison 3
    # flex 3
    # gettext 3
    # texinfo 3
    # ncurses 3
    # vim 3
    # git 3
    # gperf 3
    # automake 3
    # autoconf 3
    # libtool 3
    # pkg-config 3
    # libs & utils
    # gmp 1
    # libmpc 1
    # mpfr 1
    # isl 1
    # binutils 1
    # elfutils 1
    # expat 1
    # genromfs 1
    # picocom 1
    # ubootTools 1
    # utillinux 1
    # NuttX‑specific bits
    # kconfig-frontends 3
    # python3Packages.kconfiglib 3
    # gcc-arm-embedded 3
  ];

  # programs.vim = {
  #   enable = true;
  #   defaultEditor = true; # Exports EDITOR="vim" globally
  # };

  # nixpkgs.config.permittedInsecurePackages = [
  #   "electron-33.4.11"
  # ];

  # ########
  # # Sound #
  # ########
  # services.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };

  #################
  # System Groups #
  #################
  # users.users.ludovic = {
  #   isNormalUser = true;
  #   description = "ludovic";
  #   extraGroups = [
  #     "networkmanager"
  #     "wheel"
  #     "docker"
  #     "input"
  #   ];
  #   shell = pkgs.zsh;
  #   ignoreShellProgramCheck = true;
  # };

  ##################
  # System Services#
  ##################
#   services.printing.enable = true;
#   virtualisation.docker.enable = true;

#   nix.settings.experimental-features = [
#     "nix-command"
#     "flakes"
#   ];

#   system.stateVersion = "25.05";
# s}
