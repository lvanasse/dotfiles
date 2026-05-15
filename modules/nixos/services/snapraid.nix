{ ... }:
{
  flake.modules.nixos."services.snapraid" =
    { pkgs, ... }:
    let
      stateRoot = "/var/lib/snapraid-status";
      apiRoot = "${stateRoot}/api";
      statusPath = "${apiRoot}/status.json";
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
        ];
        sync.interval = "Tue,Fri 03:00";
        scrub = {
          interval = "weekly";
          plan = 10;
          olderThan = 7;
        };
      };

      systemd.services.snapraid-sync = {
        postStop = updateStatusScript "sync" "{}";
        serviceConfig.ReadWritePaths = [ stateRoot ];
      };

      systemd.services.snapraid-scrub = {
        postStop = updateStatusScript "scrub" ''{"plan": "10%", "olderThanDays": 7}'';
        serviceConfig.ReadWritePaths = [ stateRoot ];
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
