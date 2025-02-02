# # TODO A way to store the gnome-terminal profile
# # TODO fix zsh not showing git status -> it's source $ZSH/oh-my-zsh.sh that was not called
# # TODO fix git to use lvanasse instead of random user

{ config, pkgs, ... }:
let
  sharedI3Config = ./i3/i3config;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  ########################
  # Boot / System basics #
  ########################
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "pc";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  nixpkgs.config.allowUnfree = true;

  services.gnome.gnome-keyring.enable = true;

  #########
  # X.org #
  #########
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "alt-intl";

  # Display manager (GDM) + Gnome
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # i3 window manager
  services.xserver.windowManager.i3 = {
    enable = true;
    extraPackages = with pkgs; [
      dmenu
      i3status
      i3blocks
      i3lock
      gnome-terminal
    ];
    configFile = sharedI3Config;
  };

  # sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
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
      (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    ];
  };


  ############
  # Packages #
  ############
  environment.systemPackages = with pkgs; [
    sway
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    mako #
  ];


  ########
  # Sound #
  ########
  hardware.pulseaudio.enable = false;
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
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };


  ##################
  # System Services#
  ##################
  services.printing.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.guest.x11 = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # State version
  system.stateVersion = "24.11";
}
