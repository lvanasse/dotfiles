{ config, ... }:
let
  flakeConfig = config;
in
{
  flake.modules.homeManager.programs =
    { config, ... }:
    let
      homeDir = config.home.homeDirectory;
      ccsRoot = "${homeDir}/ti/ccs2050/ccs";
      ccsBinary = "${ccsRoot}/theia/ccstudio";
      ccsIcon = "${ccsRoot}/doc/ccs.ico";
    in
    {
      imports = [
        flakeConfig.flake.modules.homeManager.terminal
        flakeConfig.flake.modules.homeManager."programs.nix"
        flakeConfig.flake.modules.homeManager."programs.ssh"
        flakeConfig.flake.modules.homeManager."programs.aider"
        flakeConfig.flake.modules.homeManager."programs.development"
        flakeConfig.flake.modules.homeManager."programs.slack"
        flakeConfig.flake.modules.homeManager."programs.vesktop"
        flakeConfig.flake.modules.homeManager."programs.codex"
        flakeConfig.flake.modules.homeManager."programs.rtk"
        flakeConfig.flake.modules.homeManager."programs.jira"
        flakeConfig.flake.modules.homeManager."programs.firefox"
        flakeConfig.flake.modules.homeManager."programs.email"
        flakeConfig.flake.modules.homeManager."programs.calendar"
      ];

      home.file.".local/bin/ccs" = {
        executable = true;
        text = ''
          #!/bin/sh
          set -eu

          export CHROME_DESKTOP=ccs.desktop

          WAYLAND_FLAGS=""
          if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
            ozone_platform="''${CCS_OZONE_PLATFORM:-x11}"
            WAYLAND_FLAGS="--ozone-platform=''${ozone_platform}"
          fi

          GPU_FLAGS=""
          if [ "''${CCS_DISABLE_GPU:-0}" = "1" ]; then
            GPU_FLAGS="--disable-gpu --disable-gpu-compositing"
          fi

          exec "${ccsBinary}" \
            --disable-setuid-sandbox \
            --no-sandbox \
            $WAYLAND_FLAGS \
            $GPU_FLAGS \
            "$@"
        '';
      };

      xdg.desktopEntries.ccs = {
        name = "CCS 20.5.0";
        comment = "Texas Instruments Code Composer Studio";
        genericName = "Embedded IDE";
        exec = "${homeDir}/.local/bin/ccs %U";
        icon = ccsIcon;
        type = "Application";
        startupNotify = true;
        categories = [
          "Development"
          "IDE"
          "Electronics"
        ];
        settings.StartupWMClass = "ccstudio";
      };
    };
}
