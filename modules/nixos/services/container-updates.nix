{ ... }:
{
  flake.modules.nixos."services.container-updates" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      stateRoot = "/var/lib/container-updates";
      statusPath = "${stateRoot}/status.json";
      excludedContainers = [ "dockhand" ];
      preferredOrder = [
        "linkwarden-postgres"
        "vikunja-postgres"
        "mariadb"
        "qbittorrent"
        "prowlarr"
        "sonarr"
        "radarr"
        "lidarr"
        "bazarr"
        "jellyfin"
        "jellyseerr"
        "calibre-web-automated"
        "calibre"
        "nextcloud"
        "shelfmark"
      ];
      healthChecks = {
        actual = {
          kind = "http";
          url = "http://127.0.0.1:5006/";
        };
        audiobookshelf = {
          kind = "http";
          url = "http://127.0.0.1:13378/";
        };
        bazarr = {
          kind = "http";
          url = "http://127.0.0.1:6767/";
        };
        calibre = {
          kind = "http";
          url = "http://127.0.0.1:8780/";
        };
        calibre-web-automated = {
          kind = "http";
          url = "http://127.0.0.1:8083/";
        };
        jellyfin = {
          kind = "http";
          url = "http://127.0.0.1:8096/";
        };
        jellyseerr = {
          kind = "http";
          url = "http://127.0.0.1:5055/";
        };
        kitchenowl = {
          kind = "http";
          url = "http://127.0.0.1:8086/";
        };
        lidarr = {
          kind = "http";
          url = "http://127.0.0.1:8686/";
        };
        linkwarden = {
          kind = "http";
          url = "http://127.0.0.1:3000/";
        };
        mariadb = {
          kind = "tcp";
          host = "127.0.0.1";
          port = 3306;
        };
        mousehole = {
          kind = "http";
          url = "http://127.0.0.1:5010/state";
        };
        standardnotes-server = {
          kind = "http";
          url = "http://127.0.0.1:3030/";
        };
        standardnotes-web = {
          kind = "http";
          url = "http://127.0.0.1:3031/";
        };
        nextcloud = {
          kind = "http";
          url = "https://127.0.0.1:444/";
        };
        prowlarr = {
          kind = "http";
          url = "http://127.0.0.1:9696/";
        };
        qbittorrent = {
          kind = "http";
          url = "http://127.0.0.1:8081/";
        };
        radarr = {
          kind = "http";
          url = "http://127.0.0.1:7878/";
        };
        shelfmark = {
          kind = "http";
          url = "http://127.0.0.1:8084/";
        };
        sonarr = {
          kind = "http";
          url = "http://127.0.0.1:8989/";
        };
        vaultwarden = {
          kind = "http";
          url = "http://127.0.0.1:4743/";
        };
        vikunja = {
          kind = "http";
          url = "http://127.0.0.1:3456/";
        };
      };
      containerNames = builtins.filter (name: !(builtins.elem name excludedContainers)) (
        builtins.attrNames config.virtualisation.oci-containers.containers
      );
      orderedNames =
        (builtins.filter (name: builtins.elem name containerNames) preferredOrder)
        ++ (builtins.sort builtins.lessThan (
          builtins.filter (name: !(builtins.elem name preferredOrder)) containerNames
        ));
      managedContainers = map (
        name:
        let
          container = config.virtualisation.oci-containers.containers.${name};
        in
        {
          inherit name;
          unit = "docker-${name}.service";
          image = container.image;
          health = healthChecks.${name} or { kind = "docker"; };
        }
      ) orderedNames;
      managedContainersJson = builtins.toJSON managedContainers;
      updateScript = pkgs.writeShellScript "container-update" ''
        set -euo pipefail

        mkdir -p "${stateRoot}"

        if ${pkgs.systemd}/bin/systemctl --quiet is-active snapraid-sync.service \
          || ${pkgs.systemd}/bin/systemctl --quiet is-active snapraid-scrub.service; then
          echo "container-update: SnapRAID is active; skipping updates"
          exit 0
        fi

        ${pkgs.python3}/bin/python3 <<'PY'
        import json
        import socket
        import ssl
        import subprocess
        import sys
        import time
        import urllib.error
        import urllib.request
        from datetime import datetime, timezone
        from pathlib import Path

        apps = ${managedContainersJson}
        docker = "${pkgs.docker_29}/bin/docker"
        systemctl = "${pkgs.systemd}/bin/systemctl"
        status_path = Path("${statusPath}")
        wait_seconds = 300
        poll_seconds = 5

        def now():
            return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        def run(args, check=False):
            return subprocess.run(
                args,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=check,
            )

        def docker_inspect(name):
            proc = run([docker, "inspect", name])
            if proc.returncode != 0:
                return None
            return json.loads(proc.stdout)[0]

        def image_id(ref):
            proc = run([docker, "image", "inspect", ref, "--format", "{{.Id}}"])
            if proc.returncode != 0:
                return None
            return proc.stdout.strip() or None

        def container_image_id(name):
            container = docker_inspect(name)
            if not container:
                return None
            return container.get("Image")

        def container_running(name):
            container = docker_inspect(name)
            if not container:
                return False
            return (container.get("State") or {}).get("Status") == "running"

        def docker_health_ok(name):
            container = docker_inspect(name)
            if not container:
                return False
            state = container.get("State") or {}
            if state.get("Status") != "running":
                return False
            health = state.get("Health")
            return health is None or health.get("Status") == "healthy"

        def http_ok(url):
            context = ssl._create_unverified_context()
            request = urllib.request.Request(url, method="GET")
            try:
                with urllib.request.urlopen(request, timeout=10, context=context) as response:
                    return 200 <= response.status < 400
            except urllib.error.HTTPError as error:
                return 200 <= error.code < 400
            except Exception:
                return False

        def tcp_ok(host, port):
            try:
                with socket.create_connection((host, int(port)), timeout=10):
                    return True
            except OSError:
                return False

        def app_ok(app):
            health = app["health"]
            kind = health.get("kind", "docker")
            if kind == "http":
                return container_running(app["name"]) and http_ok(health["url"])
            if kind == "tcp":
                return container_running(app["name"]) and tcp_ok(health["host"], health["port"])
            return docker_health_ok(app["name"])

        def wait_ok(app):
            deadline = time.monotonic() + wait_seconds
            while time.monotonic() < deadline:
                if app_ok(app):
                    return True
                time.sleep(poll_seconds)
            return app_ok(app)

        def start_unit(app):
            unit = app["unit"]
            name = app["name"]
            run([systemctl, "stop", unit])
            run([docker, "rm", "-f", name])
            run([systemctl, "reset-failed", unit])
            return run([systemctl, "start", unit])

        results = []
        failures = 0

        for app in apps:
            name = app["name"]
            image = app["image"]
            unit = app["unit"]
            result = {
                "name": name,
                "unit": unit,
                "image": image,
                "startedAt": now(),
                "status": "unknown",
            }

            old_image = container_image_id(name) or image_id(image)
            result["previousImageId"] = old_image

            pull = run([docker, "pull", image])
            result["pullOutput"] = "\n".join((pull.stdout + pull.stderr).splitlines()[-20:])
            if pull.returncode != 0:
                result["status"] = "pull-failed"
                failures += 1
                results.append(result)
                continue

            new_image = image_id(image)
            result["newImageId"] = new_image

            if old_image and new_image == old_image and app_ok(app):
                result["status"] = "already-current"
                results.append(result)
                continue

            start = start_unit(app)
            if start.returncode != 0:
                result["status"] = "start-failed"
                result["error"] = start.stderr.strip() or start.stdout.strip()
                failures += 1
                results.append(result)
                continue

            if wait_ok(app):
                result["status"] = "updated"
                results.append(result)
                continue

            result["status"] = "health-failed"
            if old_image:
                tag = run([docker, "tag", old_image, image])
                result["rollbackTagOutput"] = "\n".join((tag.stdout + tag.stderr).splitlines()[-20:])
                rollback_start = start_unit(app)
                result["rollbackStartOutput"] = "\n".join(
                    (rollback_start.stdout + rollback_start.stderr).splitlines()[-20:]
                )
                if rollback_start.returncode == 0 and wait_ok(app):
                    result["status"] = "rolled-back"
                else:
                    result["status"] = "rollback-failed"
                    failures += 1
            else:
                result["status"] = "rollback-unavailable"
                failures += 1

            results.append(result)

        payload = {
            "checkedAt": now(),
            "status": "failed" if failures else "ok",
            "failures": failures,
            "results": results,
        }
        status_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

        if failures:
            sys.exit(1)
        PY
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d ${stateRoot} 0755 root root -"
      ];

      systemd.services.container-update = {
        description = "Update NixOS-managed Docker containers with health-checked rollback";
        after = [
          "docker.service"
          "network-online.target"
        ];
        wants = [
          "docker.service"
          "network-online.target"
        ];
        path = with pkgs; [
          bash
          coreutils
          docker_29
          systemd
        ];
        script = ''
          set -euo pipefail
          ${updateScript}
        '';
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "90min";
        };
      };

      systemd.timers.container-update = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "04:30";
          Persistent = true;
          RandomizedDelaySec = "30min";
          Unit = "container-update.service";
        };
      };
    };
}
