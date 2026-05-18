{ ... }:
{
  flake.modules.nixos."services.docker-health" =
    { pkgs, ... }:
    let
      dockerHealthPort = 8095;
      stateRoot = "/var/lib/docker-health";
      apiRoot = "${stateRoot}/api";
      statusPath = "${apiRoot}/status.json";
      writeDefaultStatus = ''
        mkdir -p "${apiRoot}"
        if [ ! -f "${statusPath}" ]; then
          cat > "${statusPath}" <<'EOF'
        {
          "checkedAt": null,
          "overall": {
            "status": "not-run"
          },
          "summary": {
            "total": 0,
            "running": 0,
            "healthy": 0,
            "unhealthy": 0,
            "restarting": 0,
            "exited": 0,
            "failed": 0
          },
          "failed": {
            "names": "none"
          }
        }
        EOF
        fi
      '';
      collectScript = pkgs.writeShellScript "docker-health-collect" ''
        set -euo pipefail

        ${writeDefaultStatus}

        tmp="$(mktemp "${apiRoot}/status.json.XXXXXX")"

        ${pkgs.python3}/bin/python3 - "$tmp" "${statusPath}" <<'PY'
        import json
        import subprocess
        import sys
        from datetime import datetime, timezone
        from pathlib import Path

        tmp_path = Path(sys.argv[1])
        status_path = Path(sys.argv[2])

        docker_bin = "${pkgs.docker}/bin/docker"

        ids_proc = subprocess.run(
            [docker_bin, "ps", "-aq", "--no-trunc"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

        payload = {
            "checkedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "overall": {"status": "ok"},
            "summary": {
                "total": 0,
                "running": 0,
                "healthy": 0,
                "unhealthy": 0,
                "restarting": 0,
                "exited": 0,
                "failed": 0,
            },
            "failed": {"names": "none"},
        }

        if ids_proc.returncode != 0:
            payload["overall"]["status"] = "critical"
            payload["failed"]["names"] = f"docker ps failed: {ids_proc.stderr.strip() or 'unknown error'}"
        else:
            container_ids = [line.strip() for line in ids_proc.stdout.splitlines() if line.strip()]

            if container_ids:
                inspect_proc = subprocess.run(
                    [docker_bin, "inspect", *container_ids],
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    check=False,
                )

                if inspect_proc.returncode != 0:
                    payload["overall"]["status"] = "critical"
                    payload["failed"]["names"] = f"docker inspect failed: {inspect_proc.stderr.strip() or 'unknown error'}"
                else:
                    containers = json.loads(inspect_proc.stdout)
                    failed_names = []

                    for container in containers:
                        name = container.get("Name", "").lstrip("/") or container.get("Config", {}).get("Hostname", "unknown")
                        state = container.get("State") or {}
                        status = state.get("Status", "unknown")
                        health = (state.get("Health") or {}).get("Status")

                        payload["summary"]["total"] += 1

                        if status == "running":
                            payload["summary"]["running"] += 1
                            if health == "unhealthy":
                                payload["summary"]["unhealthy"] += 1
                                failed_names.append(name)
                            else:
                                payload["summary"]["healthy"] += 1
                        elif status == "restarting":
                            payload["summary"]["restarting"] += 1
                            failed_names.append(name)
                        else:
                            payload["summary"]["exited"] += 1
                            failed_names.append(name)

                    payload["summary"]["failed"] = len(failed_names)
                    payload["failed"]["names"] = ", ".join(failed_names) if failed_names else "none"

                    if payload["summary"]["failed"] > 0:
                        payload["overall"]["status"] = "critical"
                    elif payload["summary"]["healthy"] < payload["summary"]["running"]:
                        payload["overall"]["status"] = "warning"

        tmp_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        tmp_path.replace(status_path)
        PY
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d ${stateRoot} 0755 root root -"
        "d ${apiRoot} 0755 root root -"
      ];

      systemd.services.docker-health = {
        description = "Collect Docker container health status for Homepage";
        after = [ "docker.service" ];
        wants = [ "docker.service" ];
        path = with pkgs; [
          bash
          coreutils
          docker
          python3
        ];
        script = ''
          set -euo pipefail
          ${collectScript}
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };

      systemd.timers.docker-health = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "1min";
          Persistent = true;
        };
      };

      systemd.services.docker-health-api = {
        description = "Docker health status API";
        wantedBy = [ "multi-user.target" ];
        after = [ "docker.service" "network.target" ];
        wants = [ "docker.service" ];
        path = with pkgs; [
          bash
          coreutils
          python3
        ];
        script = ''
          set -euo pipefail
          ${writeDefaultStatus}
          exec ${pkgs.python3}/bin/python3 -m http.server ${toString dockerHealthPort} --bind 127.0.0.1 --directory "${apiRoot}"
        '';
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
}
