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

  ######################################
  # i3wm & swaywm user-level config
  ######################################
  # xsession.windowManager.i3 = {
  #   enable = true;
  #   config = {

  #     # General settings
  #     modifier = "Mod4";
  #     fonts =
  #       {
  #         names = [ "System San Francisco Display" "FontAwesome5Free" ];
  #         style = "Bold Semi-Condensed";
  #         size = 11.0;
  #       };
  #     floating.modifier = "Mod4";
  #     terminal = "gnome-terminal";

  #     # Keybindings
  #     keybindings = {
  #       "$mod+Return" = "exec gnome-terminal";
  #       "$mod+Shift+q" = "kill";
  #       "$mod+d" = "exec dmenu_run";
  #       "$mod+j" = "focus left";
  #       "$mod+k" = "focus down";
  #       "$mod+l" = "focus up";
  #       "$mod+semicolon" = "focus right";
  #       "$mod+Left" = "focus left";
  #       "$mod+Down" = "focus down";
  #       "$mod+Up" = "focus up";
  #       "$mod+Right" = "focus right";
  #       "$mod+Shift+j" = "move left";
  #       "$mod+Shift+k" = "move down";
  #       "$mod+Shift+l" = "move up";
  #       "$mod+Shift+semicolon" = "move right";
  #       "$mod+Shift+Left" = "move left";
  #       "$mod+Shift+Down" = "move down";
  #       "$mod+Shift+Up" = "move up";
  #       "$mod+Shift+Right" = "move right";
  #       "$mod+h" = "split h";
  #       "$mod+v" = "split v";
  #       "$mod+f" = "fullscreen";
  #       "$mod+s" = "layout stacking";
  #       "$mod+w" = "layout tabbed";
  #       "$mod+e" = "layout toggle split";
  #       "$mod+Shift+space" = "floating toggle";
  #       "$mod+space" = "focus mode_toggle";
  #       "$mod+a" = "focus parent";
  #       "$mod+Shift+x" = "exec /home/ludovic/.config/i3/i3lock.sh";
  #       "$mod+Shift+z" = "exec systemctl";
  #       "XF86AudioRaiseVolume" = "exec --no-startup-id pactl -- set-sink-volume 0 +5%";
  #       "XF86AudioLowerVolume" = "exec --no-startup-id pactl -- set-sink-volume 0 -5%";
  #       "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute 0 toggle";
  #       "XF86MonBrightnessUp" = "exec xbacklight -inc 20";
  #       "XF86MonBrightnessDown" = "exec xbacklight -dec 20";
  #       "$mod+Tab" = "workspace back_and_forth";
  #       "$mod+Shift+c" = "reload";
  #       "$mod+Shift+r" = "restart";
  #       "$mod+Shift+e" =
  #         "exec i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -b 'Yes, exit i3' 'i3-msg exit'";
  #     };

  #     # Define a resize mode
  #     modes = {
  #       "resize" = {
  #         "j" = "resize shrink width 10 px or 10 ppt";
  #         "k" = "resize grow height 10 px or 10 ppt";
  #         "l" = "resize shrink height 10 px or 10 ppt";
  #         "semicolon" = "resize grow width 10 px or 10 ppt";
  #         "Left" = "resize shrink width 10 px or 10 ppt";
  #         "Down" = "resize grow height 10 px or 10 ppt";
  #         "Up" = "resize shrink height 10 px or 10 ppt";
  #         "Right" = "resize grow width 10 px or 10 ppt";
  #         "Return" = "mode default";
  #         "Escape" = "mode default";
  #       };
  #     };

  #     # Window assignment: assign programs to workspaces
  #     # assigns = {
  #     #   "pavucontrol" = [{ value = "10: Music"; }];
  #     #   "discord" = [{ value = "11: IM"; }];
  #     #   "Slack" = [{ value = "11: IM"; }];
  #     # };


  #     # Bind workspaces to outputs
  #     workspaceOutputAssign = [
  #       { workspace = "1"; output = "HDMI-A-1"; }
  #       { workspace = "3"; output = "DVI-D-0"; }
  #       { workspace = "10: Music"; output = "DVI-D-0"; }
  #       { workspace = "11: IM"; output = "DVI-D-0"; }
  #     ];


  #     # Bar configuration
  #     bars = [
  #       {
  #         statusCommand = "i3blocks -vv -c ~/Code/dotfiles/i3/i3blocks.conf";
  #         fonts = {
  #           names = [ "System San Francisco Display" "FontAwesome5Free" ];
  #           style = "Bold Semi-Condensed";
  #           size = 11.0;
  #         };
  #         position = "bottom";
  #         trayOutput = "HDMI-A-0";
  #         colors = {
  #           separator = "${base03}";
  #           background = "${base01}";
  #           statusline = "${base05}";
  #           focusedWorkspace = {
  #             background = "${base01}";
  #             border = "${base01}";
  #             text = "${base07}";
  #           };
  #           activeWorkspace = {
  #             background = "${base01}";
  #             border = "${base02}";
  #             text = "${base03}";
  #           };
  #           inactiveWorkspace = {
  #             background = "${base01}";
  #             border = "${base01}";
  #             text = "${base03}";
  #           };
  #           urgentWorkspace = {
  #             background = "${base01}";
  #             border = "${base01}";
  #             text = "${base03}";
  #           };
  #         };
  #       }
  #     ];

  #     # Startup commands
  #     startup = [
  #       { command = "pavucontrol"; }
  #       { command = "discord"; }
  #       { command = "slack"; }
  #       { command = "nm-applet"; }
  #       { command = "/home/ludovic/.screenlayout/default.sh"; }
  #       { command = "xcompmgr"; }
  #       { command = "nitrogen --restore"; }
  #     ];
  #   };
  #   extraConfig = ''
  #     client.focused          ${base01} ${base01} ${base07} ${base0F}
  #     client.focused_inactive ${base01} ${base01} ${base03} ${base0F}
  #     client.unfocused        ${base01} ${base01} ${base03} ${base0F}
  #     client.urgent           ${base02} ${base08} ${base00} ${base0F}

  #     set $workspace1 "1"
  #     set $workspace2 "2"
  #     set $workspace3 "3"
  #     set $workspace4 "4"
  #     set $workspace5 "5"
  #     set $workspace6 "6"
  #     set $workspace7 "7"
  #     set $workspace8 "8" 
  #     set $workspace9 "9" 
  #     set $workspace10 "10: Music"
  #     set $workspace11 "11: IM"
  #     set $workspace12 "12"
  #     set $workspace13 "13"
  #     set $workspace14 "14"
  #     set $workspace15 "15"
  #     set $workspace16 "16"
  #     set $workspace17 "17"
  #     set $workspace18 "18"
  #     set $workspace19 "19"
  #     set $workspace20 "20"

  #     assign [class="pavucontrol"] $workspace10
  #     assign [class="discord"] $workspace11
  #     assign [class="Slack"] $workspace11
  #   '';
  # };



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
    i3
    dmenu
    i3status
    i3blocks
    i3lock
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
