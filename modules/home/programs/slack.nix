{ ... }:
{
  flake.modules.homeManager.slack =
    { pkgs, ... }:
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
    };
}
