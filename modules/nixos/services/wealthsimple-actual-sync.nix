{ inputs, ... }:
let
  secretAge = "${inputs.secrets}/server/actual-wealthsimple.env.age";
in
{
  flake.modules.nixos."services.wealthsimple-actual-sync" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.wealthsimpleActualSync;
      hasSecret = builtins.pathExists secretAge;
      secretPath = "/run/agenix/actual-wealthsimple-env";
      package = pkgs.rustPlatform.buildRustPackage {
        pname = "wealthsimple-actual-sync";
        version = "0.1.0";
        src = ../../../tools/wealthsimple-actual-sync;
        cargoHash = "sha256-MN3s/GTK9XBsuoewo1kG8wVlgojYjlzFKQRLLK1xXXg=";
      };
      notifyFailure = pkgs.writeShellApplication {
        name = "wealthsimple-actual-sync-notify-failure";
        runtimeInputs = [
          pkgs.curl
          pkgs.coreutils
          pkgs.systemd
        ];
        text = ''
          set -euo pipefail
          status="$(systemctl show wealthsimple-actual-sync.service --property=ExecMainStatus --value)"
          if [ "$status" = 20 ]; then
            message="Wealthsimple to Actual sync failed: manual reauthentication required"
            tags="warning,key"
          else
            message="Wealthsimple to Actual sync failed; inspect the service journal"
            tags="warning"
          fi

          if [ ! -r /run/agenix/ntfy-monitor-token ]; then
            exit 0
          fi
          token="$(tr -d '\n' < /run/agenix/ntfy-monitor-token)"
          printf '%s\n' \
            'fail' \
            'silent' \
            'show-error' \
            'request = "POST"' \
            'url = "http://127.0.0.1:2586/homelab-alerts"' \
            "header = \"Authorization: Bearer $token\"" \
            'header = "Title: Wealthsimple Actual sync"' \
            "header = \"Tags: $tags\"" \
            "data = \"$message\"" | curl --config -
        '';
      };
      createActualAccounts = pkgs.writeShellApplication {
        name = "wealthsimple-actual-create-accounts";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          set -euo pipefail
          actual=/run/current-system/sw/bin/actual

          ensure_account() {
            name="$1"
            if account_id="$($actual server get-id --type accounts --name "$name" 2>/dev/null)" \
              && [ -n "$account_id" ]; then
              printf 'Actual account already exists: %s (%s)\n' "$name" "$account_id"
            else
              "$actual" accounts create --name "$name" --balance 0
            fi
          }

          ensure_account "Wealthsimple Cash"
          ensure_account "Wealthsimple Credit Card"
          "$actual" accounts list --format table
        '';
      };
    in
    {
      options.services.wealthsimpleActualSync = {
        enable = lib.mkEnableOption "Wealthsimple Cash and Credit Card to Actual synchronization";
        timer.enable = lib.mkEnableOption "the daily Wealthsimple to Actual timer";
      };

      config = lib.mkIf cfg.enable {
        warnings = lib.optional (!hasSecret) ''
          Wealthsimple to Actual is installed but inactive until ${secretAge} exists.
        '';

        users.groups.wealthsimple-actual-sync = { };
        users.users.wealthsimple-actual-sync = {
          isSystemUser = true;
          group = "wealthsimple-actual-sync";
          home = "/var/lib/wealthsimple-actual-sync";
        };

        age.secrets."actual-wealthsimple-env" = lib.mkIf hasSecret {
          file = secretAge;
          path = secretPath;
          owner = "root";
          group = "root";
          mode = "0400";
        };

        environment.systemPackages = [
          package
          pkgs.curl-impersonate
        ];

        systemd.services.wealthsimple-actual-sync = {
          description = "Import finalized Wealthsimple Cash and Credit Card transactions into Actual";
          path = [ pkgs.bash ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "docker-actual.service"
          ];
          requires = [ "docker-actual.service" ];
          unitConfig = {
            ConditionPathExists = secretPath;
            OnFailure = "wealthsimple-actual-sync-notify-failure.service";
          };
          serviceConfig = {
            Type = "oneshot";
            User = "wealthsimple-actual-sync";
            Group = "wealthsimple-actual-sync";
            EnvironmentFile = secretPath;
            Environment = [
              "ACTUAL_SERVER_URL=http://127.0.0.1:5006"
              "ACTUAL_DATA_DIR=/var/lib/wealthsimple-actual-sync/actual-cache"
              "ACTUAL_CLI=/run/current-system/sw/bin/actual"
              "WEALTHSIMPLE_CURL=${pkgs.curl-impersonate}/bin/curl_chrome142"
            ];
            ExecStart = "${package}/bin/wealthsimple-actual-sync sync";
            StateDirectory = "wealthsimple-actual-sync";
            StateDirectoryMode = "0700";
            CacheDirectory = "wealthsimple-actual-sync";
            CacheDirectoryMode = "0700";
            UMask = "0077";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            ReadWritePaths = [
              "/var/lib/wealthsimple-actual-sync"
              "/var/cache/wealthsimple-actual-sync"
            ];
          };
        };

        systemd.services.wealthsimple-actual-sync-notify-failure = {
          description = "Notify about Wealthsimple to Actual sync failure";
          after = [ "ntfy-sh.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${notifyFailure}/bin/wealthsimple-actual-sync-notify-failure";
            UMask = "0077";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
          };
        };

        systemd.services.wealthsimple-actual-sync-list-actual-accounts = {
          description = "List Actual accounts for Wealthsimple importer setup";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" "docker-actual.service" ];
          requires = [ "docker-actual.service" ];
          unitConfig.ConditionPathExists = secretPath;
          serviceConfig = {
            Type = "oneshot";
            User = "wealthsimple-actual-sync";
            Group = "wealthsimple-actual-sync";
            EnvironmentFile = secretPath;
            Environment = [
              "ACTUAL_SERVER_URL=http://127.0.0.1:5006"
              "ACTUAL_DATA_DIR=/var/lib/wealthsimple-actual-sync/actual-cache"
            ];
            ExecStart = "/run/current-system/sw/bin/actual accounts list --format table";
            StateDirectory = "wealthsimple-actual-sync";
            StateDirectoryMode = "0700";
            UMask = "0077";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            ReadWritePaths = [ "/var/lib/wealthsimple-actual-sync" ];
          };
        };

        systemd.services.wealthsimple-actual-sync-create-actual-accounts = {
          description = "Create Actual accounts for Wealthsimple Cash and Credit Card";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" "docker-actual.service" ];
          requires = [ "docker-actual.service" ];
          unitConfig.ConditionPathExists = secretPath;
          serviceConfig = {
            Type = "oneshot";
            User = "wealthsimple-actual-sync";
            Group = "wealthsimple-actual-sync";
            EnvironmentFile = secretPath;
            Environment = [
              "ACTUAL_SERVER_URL=http://127.0.0.1:5006"
              "ACTUAL_DATA_DIR=/var/lib/wealthsimple-actual-sync/actual-cache"
            ];
            ExecStart = "${createActualAccounts}/bin/wealthsimple-actual-create-accounts";
            StateDirectory = "wealthsimple-actual-sync";
            StateDirectoryMode = "0700";
            UMask = "0077";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            ReadWritePaths = [ "/var/lib/wealthsimple-actual-sync" ];
          };
        };

        systemd.services.wealthsimple-actual-sync-list-wealthsimple-accounts = {
          description = "List eligible Wealthsimple Cash and Credit Card accounts";
          path = [ pkgs.bash ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "wealthsimple-actual-sync";
            Group = "wealthsimple-actual-sync";
            Environment = [
              "WEALTHSIMPLE_CURL=${pkgs.curl-impersonate}/bin/curl_chrome142"
            ];
            ExecStart = "${package}/bin/wealthsimple-actual-sync accounts";
            StateDirectory = "wealthsimple-actual-sync";
            StateDirectoryMode = "0700";
            UMask = "0077";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            ReadWritePaths = [ "/var/lib/wealthsimple-actual-sync" ];
          };
        };

        systemd.services.wealthsimple-actual-sync-stage = {
          description = "Stage and validate 90 days of Wealthsimple activity";
          path = [ pkgs.bash ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          unitConfig.ConditionPathExists = secretPath;
          serviceConfig = {
            Type = "oneshot";
            User = "wealthsimple-actual-sync";
            Group = "wealthsimple-actual-sync";
            EnvironmentFile = secretPath;
            Environment = [
              "WEALTHSIMPLE_CURL=${pkgs.curl-impersonate}/bin/curl_chrome142"
            ];
            ExecStart = "${package}/bin/wealthsimple-actual-sync stage --since 90d";
            StateDirectory = "wealthsimple-actual-sync";
            StateDirectoryMode = "0700";
            UMask = "0077";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            ReadWritePaths = [ "/var/lib/wealthsimple-actual-sync" ];
          };
        };

        systemd.services.wealthsimple-actual-sync-dry-run = {
          description = "Preview Wealthsimple Cash and Credit Card imports into Actual";
          path = [ pkgs.bash ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" "docker-actual.service" ];
          requires = [ "docker-actual.service" ];
          unitConfig.ConditionPathExists = secretPath;
          serviceConfig = {
            Type = "oneshot";
            User = "wealthsimple-actual-sync";
            Group = "wealthsimple-actual-sync";
            EnvironmentFile = secretPath;
            Environment = [
              "ACTUAL_SERVER_URL=http://127.0.0.1:5006"
              "ACTUAL_DATA_DIR=/var/lib/wealthsimple-actual-sync/actual-cache"
              "ACTUAL_CLI=/run/current-system/sw/bin/actual"
              "WEALTHSIMPLE_CURL=${pkgs.curl-impersonate}/bin/curl_chrome142"
            ];
            ExecStart = "${package}/bin/wealthsimple-actual-sync sync --dry-run";
            StateDirectory = "wealthsimple-actual-sync";
            StateDirectoryMode = "0700";
            CacheDirectory = "wealthsimple-actual-sync";
            CacheDirectoryMode = "0700";
            UMask = "0077";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            ReadWritePaths = [
              "/var/lib/wealthsimple-actual-sync"
              "/var/cache/wealthsimple-actual-sync"
            ];
          };
        };

        systemd.timers.wealthsimple-actual-sync = lib.mkIf cfg.timer.enable {
          description = "Daily Wealthsimple to Actual synchronization";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 06:15:00 America/Toronto";
            Persistent = true;
            RandomizedDelaySec = "10m";
            Unit = "wealthsimple-actual-sync.service";
          };
        };
      };
    };
}
