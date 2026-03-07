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
          export ELECTRON_NO_SANDBOX=1
          exec ${pkgs.slack}/bin/slack --disable-setuid-sandbox --no-sandbox "$@"
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
