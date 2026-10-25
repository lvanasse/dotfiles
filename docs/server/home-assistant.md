# Home Assistant on the server

The server runs Home Assistant Container at `http://192.168.0.50:8123` on the
apartment LAN and `http://server.tail7e8d6c.ts.net:8123` over Tailscale. Its
data is stored at `/mnt/ssd/appdata/docker/home-assistant`. The image is pinned
in `modules/nixos/services/home-assistant.nix` and excluded from scheduled
container updates. Review and update the pinned version deliberately.

The service seeds `configuration.yaml` and editable automations on first start
only. Subsequent Home Assistant UI edits persist in the data directory. One
automation turns on every light entity from the WiZ integration 30 minutes
before sunset, at 50% brightness and 2700 K. Another turns them off at 23:00
Sunday through Thursday. Friday and Saturday shutoff is manual. Both act once
at their scheduled time; later manual changes remain in effect until the next
scheduled action. New WiZ bulbs are included automatically after they are added
to the integration. Home Assistant uses the configured home location and
America/Toronto time zone for these schedules.

## First run

1. After the server switch, open the LAN URL, create the Home Assistant owner
   account, and set the correct home location and time zone.
2. In the WiZ phone app, set **Settings > Security > Allow local communication**
   to **Allow all controls**. If local commands still fail, switch to **Only
   verified controls**, save, then switch back to **Allow all controls** and save.
   In Home Assistant, open **Settings > Devices & services** and accept the
   discovered WiZ bulb. If it is absent, choose
   **Add integration > WiZ** and enter the bulb's LAN address. Keep the bulb and
   server on networks that can reach each other locally.
3. Open the bulb's device page, assign it to a new **Office** area, then turn it
   on, dim it, change its white temperature, and turn it off to verify control.
4. The **Lights** dashboard at `/lights-control/home` has tiles for the Office,
   Bedroom, and Living room bulbs, plus toggles for both WiZ automations. Set
   this dashboard as the default on the phone if desired. Add more light tiles
   as bulbs are installed.
5. Open **Settings > Automations & scenes** to review the WiZ on and off rules.
   Check their next scheduled runs after editing either automation.

## Android access

Install Tailscale and the Home Assistant Companion app on Android. Join the
phone to the same Tailscale network as the server, keep Tailscale connected,
and enter `http://server.tail7e8d6c.ts.net:8123` in the Companion app. Sign in
with the Home Assistant account. Test a light from the app on home Wi-Fi, then
turn off Wi-Fi and repeat on mobile data with Tailscale connected. The Tailscale
connection carries the app's HTTP traffic; the service is not exposed on the
public Internet.

## Backups

Daily automatic encrypted backups are configured with a seven-copy retention
limit. Home Assistant Container keeps them under the data directory's `backups`
folder. The encryption key is saved on the desktop at
`~/.local/share/home-assistant/backup-recovery-key.txt` (mode 0600); copy it to a
password manager and keep another copy away from this computer. The first
encrypted backup was also downloaded to
`~/.local/share/home-assistant/backups/2026-10-24-initial-encrypted.tar`. A newer
copy with all three bulbs is at
`~/.local/share/home-assistant/backups/2026-10-24-three-bulbs-encrypted.tar`.
The latest copy, including the evening schedule, is at
`~/.local/share/home-assistant/backups/2026-10-24-evening-schedule-encrypted.tar`.
In **Settings > System > Backups**, check future backup runs and download newer
copies to another device periodically.
