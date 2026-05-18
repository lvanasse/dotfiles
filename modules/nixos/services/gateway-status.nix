{ ... }:
{
  flake.modules.nixos."services.gateway-status" =
    { pkgs, ... }:
    let
      gatewayAddress = "192.168.0.1";
      gatewayStatusPort = 8094;
      gatewayStatusStateRoot = "/var/lib/gateway-status";
      gatewayStatusApiRoot = "${gatewayStatusStateRoot}/api";
      gatewayStatusPath = "${gatewayStatusApiRoot}/status.json";
      gatewayStatusScript = pkgs.writeShellScript "gateway-status-collect" ''
        set -euo pipefail

        mkdir -p "${gatewayStatusApiRoot}"
        tmp="$(mktemp "${gatewayStatusApiRoot}/status.json.XXXXXX")"

        ${pkgs.python3}/bin/python3 - "$tmp" "${gatewayStatusPath}" <<'PY'
        import json
        import pathlib
        import re
        import subprocess
        import sys
        from datetime import datetime, timezone

        tmp_path = pathlib.Path(sys.argv[1])
        status_path = pathlib.Path(sys.argv[2])

        WAN_INTERFACES = ("enp5s0", "enp5s0.40", "ppp0")
        COMMANDS = {
            "dnsmasq": ["${pkgs.systemd}/bin/systemctl", "is-active", "dnsmasq"],
            "gateway-pppoe": ["${pkgs.systemd}/bin/systemctl", "is-active", "gateway-pppoe"],
            "tailscaled": ["${pkgs.systemd}/bin/systemctl", "is-active", "tailscaled"],
            "fail2ban": ["${pkgs.systemd}/bin/systemctl", "is-active", "fail2ban"],
            "fail2ban-sshd": ["${pkgs.fail2ban}/bin/fail2ban-client", "status", "sshd"],
            "sshd-config": ["${pkgs.openssh}/bin/sshd", "-T"],
            "listen-tcp": ["${pkgs.iproute2}/bin/ss", "-H", "-ltn"],
            "listen-udp": ["${pkgs.iproute2}/bin/ss", "-H", "-lun"],
            "ruleset": ["${pkgs.nftables}/bin/nft", "-nn", "list", "ruleset"],
        }

        def run(name):
            proc = subprocess.run(
                COMMANDS[name],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            return proc.returncode, proc.stdout.strip(), proc.stderr.strip()

        def service_status(unit):
            _, stdout, _ = run(unit)
            return stdout or "unknown"

        def uptime_human():
            try:
                seconds = float(pathlib.Path("/proc/uptime").read_text(encoding="utf-8").split()[0])
            except Exception:
                return "unknown"

            remaining = int(seconds)
            days, remaining = divmod(remaining, 86400)
            hours, remaining = divmod(remaining, 3600)
            minutes, _ = divmod(remaining, 60)
            parts = []
            if days:
                parts.append(f"{days}d")
            if hours or days:
                parts.append(f"{hours}h")
            parts.append(f"{minutes}m")
            return " ".join(parts)

        def parse_fail2ban():
            enabled = service_status("fail2ban") == "active"
            if not enabled:
                return enabled, 0, 0

            rc, stdout, _ = run("fail2ban-sshd")
            if rc != 0:
                return enabled, 0, 0

            banned_match = re.search(r"Currently banned:\s*(\d+)", stdout)
            failed_match = re.search(r"Currently failed:\s*(\d+)", stdout)
            banned = int(banned_match.group(1)) if banned_match else 0
            failed = int(failed_match.group(1)) if failed_match else 0
            return enabled, banned, failed

        def password_auth_setting():
            rc, stdout, _ = run("sshd-config")
            if rc != 0:
                return "unknown"
            for line in stdout.splitlines():
                if line.startswith("passwordauthentication "):
                    return line.split()[1]
            return "unknown"

        def summarize_ports(name):
            rc, stdout, _ = run(name)
            if rc != 0 or not stdout:
                return "unknown"

            ports = set()
            for line in stdout.splitlines():
                columns = line.split()
                if len(columns) < 5:
                    continue
                local = columns[-2]
                if local.startswith("127.") or local.startswith("[::1]"):
                    continue
                if local in ("0.0.0.0:*", "[::]:*"):
                    continue
                if ":" not in local:
                    continue
                port = local.rsplit(":", 1)[-1].strip("[]")
                if port.isdigit():
                    ports.add(int(port))

            return ",".join(str(port) for port in sorted(ports)) or "none"

        def expand_ports(raw):
            raw = raw.strip()
            if not raw:
                return []
            if raw.startswith("{") and raw.endswith("}"):
                items = [item.strip() for item in raw[1:-1].split(",")]
            else:
                items = [raw]

            expanded = []
            for item in items:
                if not item:
                    continue
                if "-" in item:
                    start, end = item.split("-", 1)
                    if start.isdigit() and end.isdigit():
                        expanded.extend(range(int(start), int(end) + 1))
                        continue
                if item.isdigit():
                    expanded.append(int(item))
            return expanded

        def summarize_wan_open(proto):
            rc, stdout, _ = run("ruleset")
            if rc != 0 or not stdout:
                return "unknown"

            ports = set()
            for line in stdout.splitlines():
                stripped = line.strip()
                if " accept" not in f" {stripped} ":
                    continue
                if not any(f'iifname "{iface}"' in stripped for iface in WAN_INTERFACES):
                    continue

                direct_match = re.search(rf"{proto} dport (\{{[^}}]+\}}|[0-9-]+)", stripped)
                meta_match = re.search(rf"meta l4proto {proto} {proto} dport (\{{[^}}]+\}}|[0-9-]+)", stripped)
                match = direct_match or meta_match
                if not match:
                    continue
                ports.update(expand_ports(match.group(1)))

            return ",".join(str(port) for port in sorted(ports)) or "none"

        pppoe_status = service_status("gateway-pppoe")
        dnsmasq_status = service_status("dnsmasq")
        tailscale_status = service_status("tailscaled")
        fail2ban_enabled, fail2ban_banned, fail2ban_failed = parse_fail2ban()
        password_auth = password_auth_setting()
        listen_tcp = summarize_ports("listen-tcp")
        listen_udp = summarize_ports("listen-udp")
        wan_open_tcp = summarize_wan_open("tcp")
        wan_open_udp = summarize_wan_open("udp")

        overall = "ok"
        if pppoe_status != "active" or dnsmasq_status != "active":
            overall = "critical"
        elif (
            tailscale_status != "active"
            or not fail2ban_enabled
            or password_auth != "no"
            or wan_open_tcp != "none"
            or wan_open_udp != "none"
        ):
            overall = "warning"

        payload = {
            "checkedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "uptime": uptime_human(),
            "pppoe": {
                "status": pppoe_status,
                "iface": "ppp0",
            },
            "dnsmasq": {
                "status": dnsmasq_status,
            },
            "tailscale": {
                "status": tailscale_status,
            },
            "fail2ban": {
                "enabled": fail2ban_enabled,
                "sshd": {
                    "banned": fail2ban_banned,
                    "failed": fail2ban_failed,
                },
            },
            "ssh": {
                "passwordAuthentication": password_auth,
            },
            "exposure": {
                "listenTcp": listen_tcp,
                "listenUdp": listen_udp,
                "wanOpenTcp": wan_open_tcp,
                "wanOpenUdp": wan_open_udp,
            },
            "overall": {
                "status": overall,
            },
        }

        tmp_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        tmp_path.replace(status_path)
        PY
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d ${gatewayStatusStateRoot} 0755 root root -"
        "d ${gatewayStatusApiRoot} 0755 root root -"
      ];

      systemd.services.gateway-status = {
        description = "Collect gateway security and health status for Homepage";
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = gatewayStatusScript;
        };
      };

      systemd.timers.gateway-status = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
          Persistent = true;
        };
      };

      systemd.services.gateway-status-api = {
        description = "Gateway security status API";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        script = ''
          set -euo pipefail
          mkdir -p "${gatewayStatusApiRoot}"
          if [ ! -f "${gatewayStatusPath}" ]; then
            cat > "${gatewayStatusPath}" <<'EOF'
          {
            "checkedAt": null,
            "uptime": "unknown",
            "pppoe": {
              "status": "not-run",
              "iface": "ppp0"
            },
            "dnsmasq": {
              "status": "not-run"
            },
            "tailscale": {
              "status": "not-run"
            },
            "fail2ban": {
              "enabled": false,
              "sshd": {
                "banned": 0,
                "failed": 0
              }
            },
            "ssh": {
              "passwordAuthentication": "unknown"
            },
            "exposure": {
              "listenTcp": "unknown",
              "listenUdp": "unknown",
              "wanOpenTcp": "unknown",
              "wanOpenUdp": "unknown"
            },
            "overall": {
              "status": "not-run"
            }
          }
          EOF
          fi
          exec ${pkgs.python3}/bin/python3 -m http.server ${toString gatewayStatusPort} --bind ${gatewayAddress} --directory "${gatewayStatusApiRoot}"
        '';
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
}
