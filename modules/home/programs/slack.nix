{ ... }:
{
  flake.modules.homeManager."programs.slack" =
    { pkgs, config, ... }:
    {
      # Slack needs --no-sandbox because the SUID helper can't be set in the Nix store.
      home.file.".local/bin/slack" = {
        executable = true;
        text = ''
          #!/bin/sh
          set -eu

          export ELECTRON_NO_SANDBOX=1

          WAYLAND_FLAGS=""
          if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
            WAYLAND_FLAGS="--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer"
          fi

          GPU_FLAGS=""
          if [ "''${SLACK_DISABLE_GPU:-0}" = "1" ]; then
            GPU_FLAGS="--disable-gpu --disable-gpu-compositing"
          fi

          exec ${pkgs.slack}/bin/slack \
            --disable-setuid-sandbox \
            --no-sandbox \
            $WAYLAND_FLAGS \
            $GPU_FLAGS \
            "$@"
        '';
      };

      # Override the .desktop file so xdg-open slack:// uses the wrapper, not the
      # bare Nix binary (which crashes due to the missing SUID sandbox).
      xdg.desktopEntries.slack = {
        name = "Slack";
        comment = "Slack Desktop";
        genericName = "Slack Client for Linux";
        exec = "${config.home.homeDirectory}/.local/bin/slack -s %U";
        icon = "slack";
        type = "Application";
        startupNotify = true;
        categories = [
          "GNOME"
          "GTK"
          "Network"
          "InstantMessaging"
        ];
        mimeType = [ "x-scheme-handler/slack" ];
        settings.StartupWMClass = "Slack";
      };
    };
}
