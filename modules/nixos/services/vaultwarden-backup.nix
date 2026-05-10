{ inputs, ... }:
let
  vaultwardenBackupEnvAge = "${inputs.secrets}/server/vaultwarden-kdrive-backup.env.age";
  vaultwardenBackupEnvPlainRepo = "${inputs.secrets}/server/vaultwarden-kdrive-backup.env";
  vaultwardenBackupEnvPlainOverride = ../../../overrides/vaultwarden-kdrive-backup.env;
in
{
  flake.modules.nixos."services.vaultwarden-backup" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasVaultwardenBackupEnvAge = builtins.pathExists vaultwardenBackupEnvAge;
      hasVaultwardenBackupEnvPlainRepo = builtins.pathExists vaultwardenBackupEnvPlainRepo;
      hasVaultwardenBackupEnvPlainOverride = builtins.pathExists vaultwardenBackupEnvPlainOverride;
      hasVaultwardenBackupEnv =
        hasVaultwardenBackupEnvAge
        || hasVaultwardenBackupEnvPlainRepo
        || hasVaultwardenBackupEnvPlainOverride;
      vaultwardenBackupEnvPath =
        if hasVaultwardenBackupEnvAge then
          config.age.secrets."vaultwarden-kdrive-backup-env".path
        else if hasVaultwardenBackupEnvPlainOverride then
          toString vaultwardenBackupEnvPlainOverride
        else
          toString vaultwardenBackupEnvPlainRepo;
      sourceRoot = "/mnt/data3/appdata/vaultwarden";
      stateRoot = "/var/lib/vaultwarden-kdrive-backup";
      snapshotRoot = "${stateRoot}/snapshot";
      restoreRoot = "${stateRoot}/restore-test";
      apiRoot = "${stateRoot}/api";
      statusPath = "${apiRoot}/status.json";
      rcloneConfigPath = "/run/restic-backups-vaultwarden-kdrive/rclone.conf";
      writeDefaultStatus = ''
                mkdir -p "${apiRoot}"
                if [ ! -f "${statusPath}" ]; then
                  cat > "${statusPath}" <<'EOF'
        {
          "backup": {
            "status": "not-run",
            "finishedAt": null,
            "exitStatus": null
          },
          "restoreTest": {
            "status": "not-run",
            "finishedAt": null,
            "exitStatus": null
          }
        }
        EOF
                fi
      '';
      updateStatusScript = field: ''
                ${writeDefaultStatus}
                ${pkgs.python3}/bin/python3 - <<'PY'
        import json
        import os
        from datetime import datetime, timezone
        from pathlib import Path

        status_path = Path("${statusPath}")
        data = json.loads(status_path.read_text(encoding="utf-8"))
        data["${field}"] = {
            "status": os.environ.get("SERVICE_RESULT", "unknown"),
            "finishedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "exitStatus": os.environ.get("EXIT_STATUS"),
        }
        status_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        PY
      '';
    in
    {
      age.secrets = lib.mkIf hasVaultwardenBackupEnvAge {
        "vaultwarden-kdrive-backup-env" = {
          file = vaultwardenBackupEnvAge;
          path = "/run/agenix/vaultwarden-kdrive-backup-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${stateRoot} 0700 root root -"
        "d ${snapshotRoot} 0700 root root -"
        "d ${restoreRoot} 0700 root root -"
        "d ${apiRoot} 0700 root root -"
      ];

      services.restic.backups.vaultwarden-kdrive = lib.mkIf hasVaultwardenBackupEnv {
        initialize = true;
        paths = [ snapshotRoot ];
        environmentFile = vaultwardenBackupEnvPath;
        backupPrepareCommand = ''
                    set -euo pipefail

                    : "''${RESTIC_REPOSITORY:?missing RESTIC_REPOSITORY}"
                    : "''${RESTIC_PASSWORD:?missing RESTIC_PASSWORD}"
                    : "''${KDRIVE_ID:?missing KDRIVE_ID}"
                    : "''${KDRIVE_USER:?missing KDRIVE_USER}"
                    : "''${KDRIVE_PASSWORD:?missing KDRIVE_PASSWORD}"

                    if [ ! -d "${sourceRoot}" ]; then
                      echo "[vaultwarden-kdrive-backup] source directory ${sourceRoot} does not exist"
                      exit 1
                    fi

                    rm -rf "${snapshotRoot}"
                    mkdir -p "${snapshotRoot}"
                    mkdir -p "$(dirname "${rcloneConfigPath}")"

                    # Use SQLite's backup mode for a consistent DB copy while Vaultwarden stays online.
                    ${pkgs.rsync}/bin/rsync -a --delete --exclude 'db.sqlite3' "${sourceRoot}/" "${snapshotRoot}/"
                    if [ -f "${sourceRoot}/db.sqlite3" ]; then
                      ${pkgs.sqlite}/bin/sqlite3 "${sourceRoot}/db.sqlite3" ".backup '${snapshotRoot}/db.sqlite3'"
                    fi

                    umask 077
                    cat > "${rcloneConfigPath}" <<EOF
          [kdrive]
          type = webdav
          url = https://$KDRIVE_ID.connect.kdrive.infomaniak.com
          vendor = other
          user = $KDRIVE_USER
          pass = $(${pkgs.rclone}/bin/rclone obscure "$KDRIVE_PASSWORD")
          EOF
        '';
        backupCleanupCommand = ''
          rm -rf "${snapshotRoot}"
          rm -f "${rcloneConfigPath}"
        '';
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 5"
          "--keep-monthly 12"
        ];
        checkOpts = [ "--read-data-subset=5%" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "45min";
          Persistent = true;
        };
      };

      systemd.services.restic-backups-vaultwarden-kdrive = lib.mkIf hasVaultwardenBackupEnv {
        environment.RCLONE_CONFIG = rcloneConfigPath;
        requires = [ "mnt-data3.mount" ];
        after = [ "mnt-data3.mount" ];
        postStop = lib.mkAfter (updateStatusScript "backup");
        path = with pkgs; [
          bash
          coreutils
          python3
          rclone
          rsync
          sqlite
        ];
      };

      systemd.services.vaultwarden-kdrive-restore-test = lib.mkIf hasVaultwardenBackupEnv {
        description = "Weekly Vaultwarden restore smoke test";
        after = [
          "mnt-data3.mount"
          "network-online.target"
        ];
        requires = [ "mnt-data3.mount" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [
          bash
          coreutils
          python3
          rclone
          restic
          sqlite
        ];
        script = ''
          set -euo pipefail

                    ${writeDefaultStatus}

                    : "''${RESTIC_REPOSITORY:?missing RESTIC_REPOSITORY}"
                    : "''${RESTIC_PASSWORD:?missing RESTIC_PASSWORD}"
                    : "''${KDRIVE_ID:?missing KDRIVE_ID}"
                    : "''${KDRIVE_USER:?missing KDRIVE_USER}"
                    : "''${KDRIVE_PASSWORD:?missing KDRIVE_PASSWORD}"

          rm -rf "${restoreRoot}"
          mkdir -p "${restoreRoot}"
          mkdir -p "$(dirname "${rcloneConfigPath}")"

          umask 077
          cat > "${rcloneConfigPath}" <<EOF
          [kdrive]
          type = webdav
          url = https://$KDRIVE_ID.connect.kdrive.infomaniak.com
          vendor = other
          user = $KDRIVE_USER
          pass = $(${pkgs.rclone}/bin/rclone obscure "$KDRIVE_PASSWORD")
          EOF

          export RCLONE_CONFIG="${rcloneConfigPath}"
          export RESTIC_PASSWORD
          export RESTIC_REPOSITORY

          ${pkgs.restic}/bin/restic restore latest --target "${restoreRoot}"

          test -f "${restoreRoot}${snapshotRoot}/db.sqlite3"
          [ "$(${pkgs.sqlite}/bin/sqlite3 "${restoreRoot}${snapshotRoot}/db.sqlite3" 'PRAGMA integrity_check;')" = "ok" ]

          rm -rf "${restoreRoot}"
          rm -f "${rcloneConfigPath}"
        '';
        serviceConfig = {
          EnvironmentFile = vaultwardenBackupEnvPath;
          Type = "oneshot";
        };
        postStop = updateStatusScript "restoreTest";
      };

      systemd.timers.vaultwarden-kdrive-restore-test = lib.mkIf hasVaultwardenBackupEnv {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Sun 04:30";
          RandomizedDelaySec = "45min";
          Persistent = true;
        };
      };

      systemd.services.vaultwarden-kdrive-backup-status-api = lib.mkIf hasVaultwardenBackupEnv {
        description = "Vaultwarden backup status API";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        path = with pkgs; [
          bash
          coreutils
          python3
        ];
        script = ''
          set -euo pipefail
          ${writeDefaultStatus}
          exec ${pkgs.python3}/bin/python3 -m http.server 8091 --bind 127.0.0.1 --directory "${apiRoot}"
        '';
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
}
