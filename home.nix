{ config, pkgs, ... }:
let
  base00 = "#101218";
  base01 = "#0E0E0E";
  base02 = "#1A1D19";
  base03 = "#A3A3A3";
  base04 = "#C0C5CE";
  base05 = "#d1d4e0";
  base06 = "#C9CCDB";
  base07 = "#ffffff";
  base08 = "#FF0000";
  base09 = "#f99170";
  base0A = "#ffefcc";
  base0B = "#a5ffe1";
  base0C = "#97e0ff";
  base0D = "#97bbf7";
  base0E = "#c0b7f9";
  base0F = "#fcc09e";
in
{
  home.username = "ludovic";
  home.homeDirectory = "/home/ludovic";

  # We need this line for older versions of HM or if you want an explicit
  # declaration of state version. For 24.11 usage:
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "kitty";
      input = {
        "*" = {
          xkb_layout = "us";
          xkb_variant = "intl";
        };
      };
    };
  };

  ######################################
  # Shell & Git user-level config
  ######################################
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "minimal";
      plugins = [ "git" "sudo" "docker" ];
    };
  };

  programs.git = {
    enable = true;
    userName = "Ludovic Vanasse";
    userEmail = "lvanasse@luxaerobot.com";
  };

  ######################################
  # Emacs user-level config
  ######################################
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    # If you want extra packages:
    extraPackages = epkgs: [
      epkgs.gruvbox-theme
    ];
  };

  ######################################
  # Personal user packages
  ######################################
  home.packages = with pkgs; [
    sway
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    mako 
    dmenu
    gnome-terminal
    firefox
    slack
    discord
    spotify
    bitwarden-desktop
    vim
    wget
    tree
    firefox
    git
    zsh
    oh-my-zsh
    rustup
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
    xdg-desktop-portal-wlr
    os-prober
    wdisplays
    swaybg
    swayidle
    kitty
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


}
