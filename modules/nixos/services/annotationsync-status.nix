{ ... }:
{
  flake.modules.nixos."services.annotationsync-status" =
    { pkgs, ... }:
    let
      stateRoot = "/var/lib/annotationsync-status";
      apiRoot = "${stateRoot}/api";
      statusPath = "${apiRoot}/status.json";
      statusPort = 8097;
      checkScript = pkgs.writeShellScript "annotationsync-status-collect" ''
        set -euo pipefail

        mkdir -p "${apiRoot}"
        tmp="$(mktemp "${apiRoot}/status.json.XXXXXX")"

        ${pkgs.python3}/bin/python3 - "$tmp" "${statusPath}" <<'PY'
        import json
        import pathlib
        import subprocess
        import sys
        from datetime import datetime, timezone

        tmp_path = pathlib.Path(sys.argv[1])
        status_path = pathlib.Path(sys.argv[2])

        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        try:
            proc = subprocess.run(
                ["${pkgs.curl}/bin/curl", "-s", "-o", "/dev/null",
                 "-w", "%{http_code}", "--max-time", "5",
                 "http://127.0.0.1:8085/"],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            code = proc.stdout.strip()
            # 401 means alive (auth required), 200/207 also fine
            if code in ("401", "200", "207"):
                status = "ok"
            elif code == "000":
                status = "down"
            else:
                status = f"http-{code}"
        except Exception:
            status = "error"

        payload = {
            "checkedAt": now,
            "status": status,
        }

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

      systemd.services.annotationsync-status = {
        description = "Check AnnotationSync WebDAV health";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = checkScript;
        };
      };

      systemd.timers.annotationsync-status = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
          Persistent = true;
        };
      };

      systemd.services.annotationsync-status-api = {
        description = "AnnotationSync status API";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        script = ''
          set -euo pipefail
          mkdir -p "${apiRoot}"
          if [ ! -f "${statusPath}" ]; then
            cat > "${statusPath}" <<'EOF'
          {"checkedAt": null, "status": "not-run"}
          EOF
          fi
          exec ${pkgs.python3}/bin/python3 -m http.server ${toString statusPort} --bind 127.0.0.1 --directory "${apiRoot}"
        '';
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
}
