import json
import hashlib
import os
import subprocess
import tempfile
from pathlib import Path
from time import sleep
from urllib.request import urlopen

app_data = Path(os.environ["TACHYON_APPDATA"])
url = "http://172.17.0.1:8877/"
for _ in range(60):
    try:
        with urlopen(url, timeout=2) as response:
            if response.status == 200:
                break
    except Exception:
        sleep(1)
else:
    raise SystemExit("Tachyon was not ready within 60 seconds")

path = app_data / "_data_/_default_/configs/application.ini"
contents = path.read_text()
section = None
found = set()
cache_hash = hashlib.sha256()
for asset in ("TACHYON_THEME", "TACHYON_PLUGIN_JS", "TACHYON_PLUGIN_PHP", "TACHYON_LOGO"):
    cache_hash.update(Path(os.environ[asset]).read_bytes())
desired = {
    ("cache", "index"): f'"tachyon-local-{cache_hash.hexdigest()[:16]}"',
    ("calendar", "enable"): "On",
    ("calendar", "allow_sync"): "On",
    ("contacts", "enable"): "On",
    ("contacts", "allow_sync"): "On",
    ("webmail", "theme"): '"GruvboxDarkHardToolbarV3@custom"',
    ("webmail", "allow_themes"): "Off",
    ("webmail", "favicon_mode"): "custom",
    ("webmail", "favicon_file"): "tachyon-favicon.svg",
    ("webmail", "login_logo_mode"): "custom",
    ("webmail", "logo_file"): "tachyon-logo-v2.svg",
    ("webmail", "logo_file_dark"): "tachyon-logo-v2.svg",
    ("webmail", "loading_description"): "Tachyon Webmail",
    ("webmail", "messages_per_page"): "100",
    ("webmail", "messages_per_page_max"): "100",
    ("plugins", "enable"): "On",
    ("plugins", "enabled_list"): "tachyon-local",
    ("labs", "folders_spec_limit"): "4",
}
lines = []
for line in contents.splitlines(keepends=True):
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        section = stripped[1:-1]
    key = stripped.split("=", 1)[0].strip() if "=" in stripped else None
    pair = (section, key)
    if pair in desired:
        found.add(pair)
        line = f"{key} = {desired[pair]}\n"
    lines.append(line)
if found != set(desired):
    raise SystemExit(f"Missing Tachyon settings: {sorted(set(desired) - found)}")
updated = "".join(lines)
if updated != contents:
    path.write_text(updated)

find_actions = subprocess.run(
    ["/run/current-system/sw/bin/docker", "exec", "tachyon", "sh", "-c",
     "find /tachyon -path '*/app/libraries/Tachyon/Actions/Calendar.php' -print -quit"],
    check=True, capture_output=True, text=True,
)
container_actions = find_actions.stdout.strip()
if not container_actions:
    raise SystemExit("Tachyon Calendar.php was not found")
with tempfile.TemporaryDirectory() as temp_dir:
    local_actions = Path(temp_dir) / "Calendar.php"
    subprocess.run(["/run/current-system/sw/bin/docker", "cp", f"tachyon:{container_actions}", local_actions], check=True)
    calendar_source = local_actions.read_text()
    if "GetActionParam('Reminder', 0)" not in calendar_source:
        marker = "\t\t$sRrule = "
        alarm = """\t\t$iReminder = max(0, (int) $this->GetActionParam('Reminder', 0));
\t\tif ($iReminder > 0) {
\t\t\t$oAlarm = $oVEvent->add('VALARM');
\t\t\t$oAlarm->add('ACTION', 'DISPLAY');
\t\t\t$oAlarm->add('DESCRIPTION', (string) $this->GetActionParam('Summary', 'Reminder'));
\t\t\t$oAlarm->add('TRIGGER', '-PT' . $iReminder . 'M');
\t\t}

"""
        if marker not in calendar_source:
            raise SystemExit("Tachyon Calendar.php reminder insertion point not found")
        local_actions.write_text(calendar_source.replace(marker, alarm + marker, 1))
        subprocess.run(["/run/current-system/sw/bin/docker", "cp", local_actions, f"tachyon:{container_actions}"], check=True)
        subprocess.run(["/run/current-system/sw/bin/docker", "exec", "tachyon", "chmod", "444", container_actions], check=True)

branding = path.parent.parent / "branding"
branding.mkdir(mode=0o700, exist_ok=True)
for name, source_name in (("tachyon-logo-v2.svg", "TACHYON_LOGO"), ("tachyon-favicon.svg", "TACHYON_FAVICON")):
    source = Path(os.environ[source_name])
    target = branding / name
    if not target.exists() or target.read_bytes() != source.read_bytes():
        target.write_bytes(source.read_bytes())
        target.chmod(0o600)
owner = branding.stat()
for name in ("tachyon-logo-v2.svg", "tachyon-favicon.svg"):
    os.chown(branding / name, owner.st_uid, owner.st_gid)

domains = path.parent.parent / "domains"
infomaniak = domains / "ludovicvanasse.com.json"
if not infomaniak.exists():
    template = domains / "default.json"
    domain = json.loads(template.read_text())
    domain["IMAP"].update({"host": "mail.infomaniak.com", "port": 993, "type": 1, "shortLogin": False})
    domain["IMAP"]["ssl"].update({"verify_peer": True, "verify_peer_name": True})
    domain["SMTP"].update({"host": "mail.infomaniak.com", "port": 587, "type": 2, "shortLogin": False, "useAuth": True})
    domain["SMTP"]["ssl"].update({"verify_peer": True, "verify_peer_name": True})
    fd = os.open(infomaniak, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        os.fchown(fd, template.stat().st_uid, template.stat().st_gid)
        with os.fdopen(fd, "w") as output:
            json.dump(domain, output, indent=4)
            output.write("\n")
    except Exception:
        infomaniak.unlink(missing_ok=True)
        raise

domain = json.loads(infomaniak.read_text())
if domain["IMAP"].get("message_list_limit") != 1000:
    domain["IMAP"]["message_list_limit"] = 1000
    infomaniak.write_text(json.dumps(domain, indent=4) + "\n")
