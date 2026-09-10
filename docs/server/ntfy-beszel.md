# Beszel and ntfy

The server runs the native NixOS `ntfy-sh` and Beszel hub services. ntfy is the
authenticated notification transport; Beszel provides host, Docker, systemd,
disk, and resource monitoring with history and alerts. The old Docker health
collector remains a Homepage status card only and does not send notifications.
Beszel is pinned to upstream 0.19.0 because that release adds container-health
and failed-systemd-service alerts that are unavailable in Nixpkgs' 0.18.7.

## Network boundaries

- ntfy listens on port `2586`; Beszel listens on port `8090`.
- Neither port is opened by the NixOS firewall. They are available to the
  existing trusted Tailscale interface, but not directly on LAN or WAN.
- Add the Cloudflare Tunnel public hostname `ntfy.ludovicvanasse.com` with the
  origin `http://192.168.0.50:2586`. Cloudflare must proxy HTTP and WebSocket
  traffic without buffering the long-lived subscription connection.
- Beszel is reached over Tailscale at
  `http://server.tail7e8d6c.ts.net:8090` and is linked from Homepage.

## Secret layout

The private secrets input contains encrypted ntfy users and access tokens:

- `server/ntfy.env.age`: declarative `ntfy-monitor` write-only and
  `ntfy-subscriber` read-only users, ACLs, and all tokens.
- `server/ntfy-monitor.token.age`: the same write-only token, exposed only to
  root for `ntfy-test` and Beszel notification setup.
- `ntfy/{android,pc,laptop,work-laptop}.token.age`: revocable subscriber
  tokens. Home Manager deploys the desktop tokens with mode `0600`.
- `server/beszel-hub.env.age`: initial Beszel administrator credentials.
- `server/beszel-agent.env.age`: the Beszel public key and a **permanent**
  universal registration token for the local agent.

`ntfy-test` publishes one authenticated test message locally without stopping
or changing an application.

## First activation and Beszel enrollment

Activation is intentionally a separate, authorized step. Once the server
generation is active:

1. Open Beszel over Tailscale and sign in with the initial encrypted admin
   credentials.
2. In **Settings → Notifications**, create an ntfy target using the monitoring
   token in this form: `ntfy://:TOKEN@ntfy.ludovicvanasse.com/homelab-alerts`.
   Configure the desired host/status and resource alerts in Beszel.
3. Create a **permanent** Beszel universal registration token. Encrypt the
   returned `KEY` and `TOKEN` as `server/beszel-agent.env.age` in the private
   secrets repository. Do not manually add `server`: a valid universal token
   registers it automatically. The module enables the local agent only when
   that file is present; it keeps its listener on `127.0.0.1:45876` until the
   WebSocket connection is established. An ephemeral token is unsuitable here,
   because a hub restart invalidates it.
4. Apply the next server generation. The agent then reports Docker and selected
   systemd units to the hub.
5. Add the Android token in the ntfy Android app. Home Manager starts the PC,
   laptop, and work-laptop subscribers after their next authorized activation.

Beszel controls alert thresholds and recovery behavior in its UI. It monitors
system/container state and resource thresholds; it does not replace a dedicated
per-application HTTP uptime checker.

## Post-activation checks

- Anonymous ntfy publish and subscribe requests receive `401`/`403`.
- The monitoring token can publish but cannot subscribe; every device token can
  subscribe but cannot publish.
- Run `ntfy-test` once, then verify Android and each active desktop session.
- Confirm the Beszel and ntfy Homepage cards open their expected services.
