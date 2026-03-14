{ ... }:
{
  flake.modules.homeManager."programs.vesktop" =
    { pkgs, config, ... }:
    {
      # Vesktop wrapper:
      # - Default to XWayland under Wayland sessions to avoid gbm/scanout crashes.
      # - Allow GPU fallback via VESKTOP_DISABLE_GPU=1 when needed.
      home.file.".local/bin/vesktop" = {
        executable = true;
        text = ''
          #!/bin/sh
          set -eu

          WAYLAND_FLAGS=""
          if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
            ozone_platform="''${VESKTOP_OZONE_PLATFORM:-x11}"
            WAYLAND_FLAGS="--ozone-platform=''${ozone_platform}"
            if [ "''${ozone_platform}" = "wayland" ]; then
              WAYLAND_FLAGS="$WAYLAND_FLAGS --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer"
            fi
          fi

          GPU_FLAGS=""
          if [ "''${VESKTOP_DISABLE_GPU:-0}" = "1" ]; then
            GPU_FLAGS="--disable-gpu --disable-gpu-compositing"
          fi

          exec ${pkgs.vesktop}/bin/vesktop \
            $WAYLAND_FLAGS \
            $GPU_FLAGS \
            "$@"
        '';
      };

      # Ensure launcher entries use the wrapper instead of the bare package binary.
      xdg.desktopEntries.vesktop = {
        name = "Vesktop";
        comment = "Vesktop Desktop";
        genericName = "Discord Client";
        exec = "${config.home.homeDirectory}/.local/bin/vesktop %U";
        icon = "vesktop";
        type = "Application";
        startupNotify = true;
        categories = [
          "Network"
          "InstantMessaging"
        ];
        settings.StartupWMClass = "vesktop";
      };
    };
}
