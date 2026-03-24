{ ... }:
{
  flake.modules.homeManager."programs.slack" =
    { pkgs, config, ... }:
    let
      slackXdgSettings = pkgs.writeShellScript "slack-xdg-settings" ''
        #!/bin/sh
        set -eu

        real_xdg_settings="${pkgs.xdg-utils}/bin/xdg-settings"
        real_xdg_mime="${pkgs.xdg-utils}/bin/xdg-mime"
        action="''${1:-}"
        subcommand="''${2:-}"

        case "$action:$subcommand" in
          set:default-url-scheme-handler)
            if [ "$#" -eq 4 ]; then
              "$real_xdg_mime" default "$4" "x-scheme-handler/$3"
              exit 0
            fi
            ;;
        esac

        exec "$real_xdg_settings" "$@"
      '';
    in
    {
      home.file.".local/libexec/slack/xdg-settings".source = slackXdgSettings;

      # Slack needs --no-sandbox because the SUID helper can't be set in the Nix store.
      home.file.".local/bin/slack" = {
        executable = true;
        text = ''
          #!/bin/sh
          set -eu

          export ELECTRON_NO_SANDBOX=1
          export CHROME_DESKTOP=slack.desktop
          export PATH="${config.home.homeDirectory}/.local/libexec/slack:$PATH"

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
