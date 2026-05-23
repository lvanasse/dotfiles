{ lib, pkgs, ... }:
{
  flake.modules.nixos."services.snapraid" =
    { pkgs, ... }:
    let
      stateRoot = "/var/lib/snapraid-status";
      apiRoot = "${stateRoot}/api";
      statusPath = "${apiRoot}/status.json";
      quiesceUnits = [
        "audiobookshelf-normalize-single-file-books-watch.service"
        "docker-actual.service"
        "docker-audiobookshelf.service"
        "docker-bazarr.service"
        "docker-calibre-web-automated.service"
        "docker-calibre.service"
        "docker-dockhand.service"
        "docker-headplane.service"
        "docker-jellyfin.service"
        "docker-jellyseerr.service"
        "docker-lidarr.service"
        "docker-linkwarden-meilisearch.service"
        "docker-linkwarden-postgres.service"
        "docker-linkwarden.service"
        "docker-mariadb.service"
        "docker-mousehole.service"
        "docker-nextcloud.service"
        "docker-prowlarr.service"
        "docker-qbittorrent.service"
        "docker-radarr.service"
        "docker-shelfmark.service"
        "docker-sonarr.service"
        "docker-vaultwarden.service"
        "docker-vikunja-postgres.service"
        "docker-vikunja.service"
      ];
      writeDefaultStatus = ''
                mkdir -p "${apiRoot}"
                if [ ! -f "${statusPath}" ]; then
                  cat > "${statusPath}" <<'EOF'
        {
          "sync": {
            "status": "not-run",
            "finishedAt": null,
            "exitStatus": null
          },
          "scrub": {
            "status": "not-run",
            "finishedAt": null,
            "exitStatus": null,
            "plan": "10%",
            "olderThanDays": 7
          }
        }
        EOF
                fi
      '';
      updateStatusScript = field: extra: ''
                ${writeDefaultStatus}
                ${pkgs.python3}/bin/python3 - <<'PY'
        import json
        import os
        from datetime import datetime, timezone
        from pathlib import Path

        status_path = Path("${statusPath}")
        data = json.loads(status_path.read_text(encoding="utf-8"))
        current = data.get("${field}", {})
        current.update({
            "status": os.environ.get("SERVICE_RESULT", "unknown"),
            "finishedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "exitStatus": os.environ.get("EXIT_STATUS"),
        })
        current.update(${extra})
        data["${field}"] = current
        status_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        PY
      '';
      quiesceWritersScript = action: ''
        echo "snapraid: ${action}ping stateful services on protected disks"
        for unit in ${lib.concatStringsSep " " (map lib.escapeShellArg quiesceUnits)}; do
          if ${pkgs.systemd}/bin/systemctl --system list-unit-files "$unit" >/dev/null 2>&1; then
            ${pkgs.systemd}/bin/systemctl --system ${action} "$unit"
          fi
        done
      '';
      resumeWritersAndUpdateStatusScript = field: extra: ''
        resume_failed=0
        for unit in ${lib.concatStringsSep " " (map lib.escapeShellArg quiesceUnits)}; do
          if ${pkgs.systemd}/bin/systemctl --system list-unit-files "$unit" >/dev/null 2>&1; then
            if ! ${pkgs.systemd}/bin/systemctl --system start "$unit"; then
              resume_failed=1
            fi
          fi
        done
        ${updateStatusScript field extra}
        exit "$resume_failed"
      '';
    in
    {
      environment.systemPackages = [ pkgs.snapraid ];

      systemd.tmpfiles.rules = [
        "d ${stateRoot} 0755 root root -"
        "d ${apiRoot} 0755 root root -"
      ];

      # Snapraid configuration - UUIDs to be filled after disk identification
      services.snapraid = {
        enable = true;
        parityFiles = [
          "/mnt/parity1/snapraid.parity"
        ];
        contentFiles = [
          "/mnt/data1/.snapraid.content"
          "/mnt/data2/.snapraid.content"
          "/mnt/data3/.snapraid.content"
        ];
        dataDisks = {
          d1 = "/mnt/data1";
          d2 = "/mnt/data2";
          d3 = "/mnt/data3";
        };
        exclude = [
          "*.unrecoverable"
          "/tmp/"
          "/lost+found/"
          "/appdata/*/logs/"
          "/appdata/*/logs.db"
          ".Thumbs.db"
          ".DS_Store"
          "*.!sync"
          ".sync/"
          ".Trash-*/"
          # Transient SQLite/runtime artifacts that frequently change during sync
          "*.db-wal"
          "*.db-shm"
          "*.db-journal"
          "*.log"
          "*.log.*"
          "*.pid"
          "*.pid.lock"
          "*.sock"
          "*ipc-socket"
          # Volatile qBittorrent config files (recreated on container start)
          "/appdata/qbittorrent/qBittorrent/categories.json"
        ];
        sync.interval = "Tue,Fri 03:00";
        scrub = {
          interval = "weekly";
          plan = 10;
          olderThan = 7;
        };
      };

      systemd.services.snapraid-sync = {
        preStart = quiesceWritersScript "stop";
        postStop = resumeWritersAndUpdateStatusScript "sync" "{}";
        serviceConfig = {
          ReadWritePaths = [ stateRoot ];
          RestrictAddressFamilies = [ "AF_UNIX" ];
        };
      };

      systemd.services.snapraid-scrub = {
        preStart = quiesceWritersScript "stop";
        postStop = resumeWritersAndUpdateStatusScript "scrub" ''{"plan": "10%", "olderThanDays": 7}'';
        serviceConfig = {
          ReadWritePaths = [ stateRoot ];
          RestrictAddressFamilies = [ "AF_UNIX" ];
        };
      };

      systemd.services.snapraid-status-api = {
        description = "SnapRAID status API";
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
          exec ${pkgs.python3}/bin/python3 -m http.server 8092 --bind 127.0.0.1 --directory "${apiRoot}"
        '';
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
}
