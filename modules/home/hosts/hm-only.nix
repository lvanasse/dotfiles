{ ... }:
{
  flake.modules.homeManager."host.hm-only" =
    { pkgs, lib, config, ... }:
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
    in
    {
      # Host-specific overrides for the Home Manager-only configuration go here.
      # Install fonts for non-NixOS systems
      fonts.fontconfig.enable = true;
      home.packages = with pkgs; [
        nerd-fonts.fira-code
        nixgl.nixGLIntel # For wrapping GL applications
      ];

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
    };
}
