{ inputs, lib, ... }:
{
  flake.modules.homeManager."services.ntfy-subscriber" =
    {
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.services.ntfySubscriber;
      tokenAge = "${inputs.secrets}/ntfy/${cfg.device}.token.age";
      hasToken = builtins.pathExists tokenAge;
      tokenPath = "${config.home.homeDirectory}/.config/ntfy/homelab-alerts.token";
      notify = pkgs.writeShellApplication {
        name = "ntfy-desktop-notify";
        runtimeInputs = [ pkgs.libnotify ];
        text = ''
          set -euo pipefail

          urgency=normal
          if [ "''${NTFY_PRIORITY:-3}" -ge 4 ]; then
            urgency=critical
          fi
          exec notify-send --urgency="$urgency" \
            "''${NTFY_TITLE:-Homelab alert}" \
            "''${NTFY_MESSAGE:-}" \
            --app-name=ntfy
        '';
      };
      subscribe = pkgs.writeShellApplication {
        name = "ntfy-homelab-subscribe";
        runtimeInputs = [
          pkgs.ntfy-sh
          pkgs.coreutils
        ];
        text = ''
          set -euo pipefail

          token="$(${pkgs.coreutils}/bin/tr -d '\n' < ${tokenPath})"
          # A live subscription without `since` receives only new events. A
          # fixed `since` value is replayed after every client reconnect.
          exec ntfy subscribe \
            --token "$token" \
            https://ntfy.ludovicvanasse.com/homelab-alerts \
            ${notify}/bin/ntfy-desktop-notify
        '';
      };
    in
    {
      options.services.ntfySubscriber = {
        enable = lib.mkEnableOption "desktop notifications from the homelab ntfy topic";
        device = lib.mkOption {
          type = lib.types.enum [
            "pc"
            "laptop"
            "work-laptop"
          ];
          description = "The per-device ntfy token to deploy.";
        };
      };

      config = lib.mkIf cfg.enable {
        age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519_personal" ];

        assertions = [
          {
            assertion = hasToken;
            message = "ntfy subscriber requires ${tokenAge}.";
          }
        ];

        home.packages = [ pkgs.ntfy-sh ];
        age.secrets."ntfy-homelab-alerts-token" = {
          file = tokenAge;
          path = tokenPath;
          mode = "0600";
        };

        systemd.user.services.ntfy-homelab-alerts = {
          Unit = {
            Description = "Desktop notifications for homelab alerts";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${subscribe}/bin/ntfy-homelab-subscribe";
            Restart = "on-failure";
            RestartSec = 10;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
