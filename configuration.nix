# TODO Emacs maybe with home-manager?
# TODO Git
# TODO A way to store the gnome-terminal profile
# TODO fix zsh not showing git status
# TODO fix git to use lvanasse instead of random user
# TODO find a good dotfiles management

{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "pc";

  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";

  i18n.defaultLocale = "en_CA.UTF-8";

  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "alt-intl";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3blocks
        i3lock
        gnome.gnome-terminal
      ];
      configFile = /home/ludovic/Code/dotfiles/i3/i3config;
    };
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
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

  services.emacs = {
    enable = true;
    package = pkgs.emacs;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  virtualisation.docker.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.ludovic = {
    isNormalUser = true;
    description = "ludovic";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  home-manager.users.ludovic = { pkgs, ... }: {
    home.stateVersion = "24.05";
    programs.git = {
      enable = true;
      userEmail = "lvanasse@luxaerobot.com";
      userName = "Ludovic Vanasse";
    };
    programs.emacs = {
      enable = true;
      package = pkgs.emacs;
    };
    # home.file."Code" = {
    #   text = "";
    #   directory = true;
    # };
  };

  programs.firefox.enable = true;

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "minimal";
      plugins = [ "git" "sudo" "docker" ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # VBox tools
  virtualisation.virtualbox.guest.enable = true;
  #virtualisation.virtualbox.guest.x11 = true;

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    vim
    wget
    firefox
    emacs
    emacsPackages.gruvbox-theme
    git
    zsh
    oh-my-zsh
    rustup
    gnome.gnome-terminal
    dmenu
    i3blocks
    i3lock
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

  # { config, pkgs, ... }:
  #   let
  #   home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  #   in
  #   {
  #   imports = [
  #     (import "${home-manager}/nixos")
  #   ];

  #   home-manager.users.ludovic = {
  #     /* The home.stateVersion option does not have a default and must be set */
  #     home.stateVersion = "18.09";
  #     /* Here goes the rest of your home-manager config, e.g. home.packages = [ pkgs.foo ]; */
  #   };
  # }


  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
