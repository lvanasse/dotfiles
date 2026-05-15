{ ... }:
{
  flake.modules.nixos."services.mergerfs" =
    { pkgs, ... }:
    let
      data1Uuid = "2cfe8f44-9b6e-4d09-8d55-fe9506759d59"; # sdb1
      data2Uuid = "0650d6e7-9270-4301-bb20-bc2701ddfa8d"; # sdc1
      data3Uuid = "7679fbf2-0302-452b-8333-2d663e276554"; # sde1
      parity1Device = "/dev/disk/by-label/parity1"; # sda1
      diskHealthStateRoot = "/var/lib/disk-health";
      diskHealthApiRoot = "${diskHealthStateRoot}/api";
      diskHealthStatusPath = "${diskHealthApiRoot}/status.json";
      diskHealthStatus = pkgs.writeShellScript "disk-health-status" ''
        set -euo pipefail

        mkdir -p "${diskHealthApiRoot}"
        tmp="$(mktemp "${diskHealthApiRoot}/status.json.XXXXXX")"

        ${pkgs.python3}/bin/python3 - "${diskHealthStatusPath}" "$tmp" <<'PY'
        import json
        import os
        import pathlib
        import re
        import shutil
        import subprocess
        import sys
        from datetime import datetime, timezone

        status_path = pathlib.Path(sys.argv[1])
        tmp_path = pathlib.Path(sys.argv[2])

        disks = [
            {
                "key": "data1",
                "label": "Data1",
                "path": "/dev/disk/by-uuid/${data1Uuid}",
                "mount": "/mnt/data1",
            },
            {
                "key": "data2",
                "label": "Data2",
                "path": "/dev/disk/by-uuid/${data2Uuid}",
                "mount": "/mnt/data2",
            },
            {
                "key": "data3",
                "label": "Data3",
                "path": "/dev/disk/by-uuid/${data3Uuid}",
                "mount": "/mnt/data3",
            },
            {
                "key": "parity1",
                "label": "Parity",
                "path": "${parity1Device}",
                "mount": "/mnt/parity1",
            },
        ]

        def whole_device(device_path):
            resolved = pathlib.Path(device_path).resolve(strict=False)
            name = resolved.name
            parent_name = None

            nvme_match = re.match(r"^(nvme\d+n\d+)p\d+$", name)
            if nvme_match:
                parent_name = nvme_match.group(1)
            else:
                sd_match = re.match(r"^([a-z]+)\d+$", name)
                if sd_match:
                    parent_name = sd_match.group(1)

            if parent_name:
                candidate = resolved.with_name(parent_name)
                if candidate.exists():
                    return str(candidate)
            return str(resolved)

        def attr_value(smart, attr_name):
            for item in smart.get("ata_smart_attributes", {}).get("table", []):
                if item.get("name") == attr_name:
                    return item.get("raw", {}).get("value")
            return None

        def mount_usage(mount):
            if not os.path.ismount(mount):
                return {"mounted": False}
            usage = shutil.disk_usage(mount)
            return {
                "mounted": True,
                "usedPercent": round((usage.used / usage.total) * 100, 1),
                "freeGiB": round(usage.free / (1024 ** 3), 1),
                "totalGiB": round(usage.total / (1024 ** 3), 1),
            }

        def smart_status(device_path):
            smart_device = whole_device(device_path)
            if not pathlib.Path(smart_device).exists():
                return {
                    "device": smart_device,
                    "smart": "missing",
                    "error": "device path does not exist",
                }

            proc = subprocess.run(
                ["${pkgs.smartmontools}/bin/smartctl", "-H", "-A", "-j", smart_device],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            try:
                smart = json.loads(proc.stdout or "{}")
            except json.JSONDecodeError:
                smart = {}

            passed = smart.get("smart_status", {}).get("passed")
            if passed is True:
                status = "passed"
            elif passed is False:
                status = "failed"
            else:
                status = "unknown"

            return {
                "device": smart_device,
                "smart": status,
                "smartExitStatus": proc.returncode,
                "temperatureC": smart.get("temperature", {}).get("current"),
                "powerOnHours": smart.get("power_on_time", {}).get("hours"),
                "reallocated": attr_value(smart, "Reallocated_Sector_Ct"),
                "pending": attr_value(smart, "Current_Pending_Sector"),
                "uncorrectable": attr_value(smart, "Offline_Uncorrectable"),
                "error": (proc.stderr or "").strip() or None,
            }

        payload = {
            "checkedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }

        statuses = []
        for disk in disks:
            entry = {
                "label": disk["label"],
                "path": disk["path"],
                "mount": disk["mount"],
            }
            entry.update(mount_usage(disk["mount"]))
            entry.update(smart_status(disk["path"]))
            payload[disk["key"]] = entry
            statuses.append(entry["smart"])

        if any(status == "failed" for status in statuses):
            overall = "critical"
        elif any(status in ("unknown", "missing") for status in statuses):
            overall = "warning"
        else:
            overall = "ok"

        payload["overall"] = {"status": overall}
        tmp_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        tmp_path.replace(status_path)
        PY
      '';
    in
    {
      environment.systemPackages = [
        pkgs.mergerfs
        pkgs.smartmontools
      ];

      # Keep mountpoint directories present across activation/reload.
      systemd.tmpfiles.rules = [
        "d /mnt/data1 0755 root root -"
        "d /mnt/data2 0755 root root -"
        "d /mnt/data3 0755 root root -"
        "d /mnt/parity1 0755 root root -"
        "d /mnt/storage 0755 root root -"
        "d /mnt/data3/appdata 0755 root root -"
        "d ${diskHealthStateRoot} 0755 root root -"
        "d ${diskHealthApiRoot} 0755 root root -"
      ];

      # Data/parity disks by stable UUID (non-destructive; no repartitioning).
      fileSystems."/mnt/data1" = {
        device = "/dev/disk/by-uuid/${data1Uuid}";
        fsType = "xfs";
        options = [
          "nofail"
          "x-systemd.device-timeout=10s"
        ];
      };

      fileSystems."/mnt/data2" = {
        device = "/dev/disk/by-uuid/${data2Uuid}";
        fsType = "xfs";
        options = [
          "nofail"
          "x-systemd.device-timeout=10s"
        ];
      };

      fileSystems."/mnt/data3" = {
        device = "/dev/disk/by-uuid/${data3Uuid}";
        fsType = "xfs";
        options = [
          "nofail"
          "x-systemd.device-timeout=10s"
        ];
      };

      # Parity disk currently has filesystem issues. Keep as on-demand mount
      # so activation does not fail while repair is pending.
      fileSystems."/mnt/parity1" = {
        device = parity1Device;
        fsType = "xfs";
        options = [
          "nofail"
          "noauto"
          "x-systemd.automount"
          "x-systemd.device-timeout=10s"
        ];
      };

      # MergerFS pool mount - combines data disks into single /mnt/storage
      systemd.mounts = [
        {
          what = "/mnt/data1:/mnt/data2:/mnt/data3";
          where = "/mnt/storage";
          type = "fuse.mergerfs";
          options =
            # qBittorrent/libtorrent defaults to mmap-based disk IO.
            # Use mergerfs' mmap-safe settings that work across older kernel/mergerfs combos.
            "defaults,nonempty,allow_other,use_ino,cache.files=auto-full,moveonenospc=true,dropcacheonclose=true,minfreespace=20G,fsname=mergerfs,category.create=pfrd,func.getattr=newest";
          wantedBy = [ "multi-user.target" ];
        }
      ];

      systemd.services.disk-health-status = {
        description = "Collect disk SMART and mount health for Homepage";
        requires = [
          "mnt-data1.mount"
          "mnt-data2.mount"
          "mnt-data3.mount"
        ];
        after = [
          "mnt-data1.mount"
          "mnt-data2.mount"
          "mnt-data3.mount"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = diskHealthStatus;
        };
      };

      systemd.timers.disk-health-status = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "3min";
          OnUnitActiveSec = "1h";
          Persistent = true;
        };
      };

      systemd.services.disk-health-status-api = {
        description = "Disk health status API";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        script = ''
            set -euo pipefail
            mkdir -p "${diskHealthApiRoot}"
            if [ ! -f "${diskHealthStatusPath}" ]; then
              cat > "${diskHealthStatusPath}" <<'EOF'
            {
              "checkedAt": null,
              "overall": {
                "status": "not-run"
              }
            }
          EOF
            fi
            exec ${pkgs.python3}/bin/python3 -m http.server 8093 --bind 127.0.0.1 --directory "${diskHealthApiRoot}"
        '';
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
}
