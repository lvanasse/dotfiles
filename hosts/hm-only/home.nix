{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  # Wrap sway with nixGL for proper OpenGL/Vulkan support on non-NixOS
  swayWrapped = pkgs.writeShellScriptBin "sway" ''
    export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profile/bin:$PATH"
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland
    export GTK_USE_PORTAL=1
    export QT_QPA_PLATFORM=wayland
    export SDL_VIDEODRIVER=wayland
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_GTK_TITLEBAR_DECORATION=system
    exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${config.wayland.windowManager.sway.package}/bin/sway "$@"
  '';
  homeDir = config.home.homeDirectory;
  jiraCfgAge = "${inputs.secrets}/jira/config.yml.age";
  jiraTokenAge = "${inputs.secrets}/jira/api_token.age";
  hasJiraCfg = builtins.pathExists jiraCfgAge;
  hasJiraToken = builtins.pathExists jiraTokenAge;
in
{
  # Host-specific overrides for the Home Manager-only configuration go here.
  # Install fonts for non-NixOS systems
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nixgl.nixGLIntel # For wrapping GL applications
    fd
    ripgrep
    dtc
    picocom
    poetry
    (python3.withPackages (ps: [ ps.tkinter ]))
  ];

  # Symlink tcl & tk data under a common parent so PyInstaller can find both
  # (Nix splits them into separate store paths, which breaks PyInstaller's path derivation)
  home.file.".local/share/tcltk/lib/${pkgs.tcl.libPrefix}".source = "${pkgs.tcl}/lib/${pkgs.tcl.libPrefix}";
  home.file.".local/share/tcltk/lib/${pkgs.tk.libPrefix}".source = "${pkgs.tk}/lib/${pkgs.tk.libPrefix}";

  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
    POETRY_VIRTUALENVS_OPTIONS_SYSTEM_SITE_PACKAGES = "true";
    TCL_LIBRARY = "${homeDir}/.local/share/tcltk/lib/${pkgs.tcl.libPrefix}";
    TK_LIBRARY = "${homeDir}/.local/share/tcltk/lib/${pkgs.tk.libPrefix}";
  };

  # Decrypt Jira CLI secrets for hm-only via agenix (if present in secrets repo).
  age.identityPaths = [
    "${homeDir}/.ssh/id_ed25519_personal"
    "${homeDir}/.ssh/id_ed25519_work"
  ];

  age.secrets =
    (lib.optionalAttrs hasJiraCfg {
      "jira-config" = {
        file = jiraCfgAge;
        path = "${homeDir}/.config/.jira/.config.yml";
        mode = "0600";
      };
    })
    // (lib.optionalAttrs hasJiraToken {
      "jira-api-token" = {
        file = jiraTokenAge;
        path = "${homeDir}/.config/.jira/JIRA_API_TOKEN";
        mode = "0600";
      };
    });

  # Use snap-friendly GTK theming on hm-only to avoid snap warnings
  gtk.theme = lib.mkForce {
    name = "Adwaita-dark";
    package = pkgs.gnome-themes-extra;
  };
  gtk.iconTheme = lib.mkForce {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
  gtk.cursorTheme = lib.mkForce {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
  };
  dconf.settings."org/gnome/desktop/interface".gtk-theme = lib.mkForce "Adwaita-dark";
  dconf.settings."org/gnome/desktop/interface".icon-theme = lib.mkForce "Adwaita";
  dconf.settings."org/gnome/desktop/interface".cursor-theme = lib.mkForce "Adwaita";

  # Wrapper for Google Chrome on Wayland to enable PipeWire screen sharing.
  home.file.".local/bin/google-chrome" = {
    executable = true;
    text = ''
      #!/bin/sh
      CHROME_BIN="/usr/bin/google-chrome"
      if [ -x /usr/bin/google-chrome-stable ]; then
        CHROME_BIN="/usr/bin/google-chrome-stable"
      fi
      if [ ! -x "$CHROME_BIN" ]; then
        echo "google-chrome not found in /usr/bin" >&2
        exit 127
      fi
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec "$CHROME_BIN" \
          --ozone-platform=wayland \
          --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer \
          "$@"
      else
        exec "$CHROME_BIN" "$@"
      fi
    '';
  };

  # Provide a PAM service file for swaylock on non-NixOS systems.
  # The nix-switch script will install this into /etc/pam.d/swaylock.
  home.file.".local/share/pam/swaylock".text = ''
    #%PAM-1.0
    auth      required pam_unix.so nullok try_first_pass
    account   required pam_unix.so
    password  required pam_unix.so
    session   required pam_unix.so
  '';

  # Electron apps need --no-sandbox because the SUID helper can't be set in the Nix store.
  home.file.".local/bin/discord" = {
    executable = true;
    text = ''
      #!/bin/sh
      export ELECTRON_NO_SANDBOX=1
      exec ${pkgs.discord}/bin/discord --disable-setuid-sandbox --no-sandbox "$@"
    '';
  };

  home.file.".local/bin/vesktop" = {
    executable = true;
    text = ''
      #!/bin/sh
      export ELECTRON_NO_SANDBOX=1
      exec ${pkgs.vesktop}/bin/vesktop --disable-setuid-sandbox --no-sandbox "$@"
    '';
  };

  home.file.".local/bin/google-chrome-stable" = {
    executable = true;
    text = ''
      #!/bin/sh
      exec "$HOME/.local/bin/google-chrome" "$@"
    '';
  };

  # Wrap wezterm with nixGL for proper OpenGL support on non-NixOS
  programs.wezterm.package = pkgs.writeShellScriptBin "wezterm" ''
    exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm "$@"
  '';
  # Wrapper package doesn't include profile.d/wezterm.sh
  programs.wezterm.enableBashIntegration = false;

  # Use wezterm as the terminal in sway (with full paths for non-NixOS)
  wayland.windowManager.sway.config = {
    terminal = lib.mkForce "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm";
  };

  # Override the sway desktop entry to use nixGL wrapper
  home.file.".local/share/wayland-sessions/sway.desktop" = lib.mkForce {
    text = ''
      [Desktop Entry]
      Name=Sway
      Comment=Wayland compositor
      Exec=${swayWrapped}/bin/sway
      TryExec=${swayWrapped}/bin/sway
      Type=Application
      DesktopNames=sway
      X-GDM-SessionRegister=true
    '';
  };

  services.kanshi = {
    enable = true;
    systemdTarget = "sway-session.target";
    settings = [
      {
        profile = {
          name = "desk";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60.001Hz";
              position = "0,1080";
            }
            {
              criteria = "DP-1";
              mode = "1920x1080@60.000Hz";
              position = "1920,0";
            }
            {
              criteria = "HDMI-A-1";
              mode = "1920x1080@60.000Hz";
              position = "0,0";
            }
          ];
        };
      }
      {
        profile = {
          name = "projector-mirror";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1080@60.001Hz";
              position = "0,0";
            }
            {
              criteria = "HDMI-A-1";
              mode = "1920x1080@60.000Hz";
              position = "0,0";
            }
          ];
        };
      }
      {
        profile = {
          name = "mobile";
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1200@60.001Hz";
              position = "0,0";
            }
          ];
        };
      }
    ];
  };
}
