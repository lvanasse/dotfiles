# Attic binary cache

The server hosts an Attic binary cache on its Tailscale interface at
`http://server.tail7e8d6c.ts.net:8080`. The firewall does not expose port 8080
to the LAN or WAN. Cache data and the SQLite database use Attic's protected
state directory under `/var/lib/atticd`; unused data is retained for 30 days.

The service and clients are intentionally fail closed during bootstrap:

- `atticd` starts only when `server/atticd.env.age` exists in the private
  secrets input.
- targets add the `dotfiles` substituter only when the public file
  `server/attic-cache-public-key` exists in that input.
- the cache is public for token-free reads over Tailscale. Uploads still require
  a scoped Attic token.

## Bootstrap

Activation and cache creation are separate, user-authorized steps.

1. Generate the server JWT key without writing it to shell history:

   ```bash
   nix run nixpkgs#openssl -- genrsa -traditional 4096 | base64 -w0
   ```

   Put it in `server/atticd.env.age` as
   `ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="..."`, encrypt it with agenix, and
   update the `secrets` flake input.

1. Apply the server generation and verify `atticd.service` before continuing.

1. Create a short-lived administrator token on the server:

   ```fish
   set attic_token (sudo atticd-atticadm make-token \
     --sub bootstrap \
     --validity 1h \
     --pull dotfiles \
     --push dotfiles \
     --create-cache dotfiles \
     --configure-cache dotfiles \
     --configure-cache-retention dotfiles)
   ```

1. On a trusted Tailscale client, log in with that token and create the public
   cache:

   ```fish
   attic login --set-default homelab \
     http://server.tail7e8d6c.ts.net:8080 \
     $attic_token
   attic cache create dotfiles --public
   attic cache info dotfiles
   set -e attic_token
   ```

1. Copy the complete `Public Key` value from `attic cache info` into the plain
   private-repository file `server/attic-cache-public-key`. It is a trust anchor,
   not a secret. Update the `secrets` input, evaluate all targets, and then apply
   them. Home Manager-only hosts must run Nix as a trusted daemon user for their
   user-level trusted-key setting to take effect.

## Uploading

Create a longer-lived token scoped to `--pull dotfiles --push dotfiles`, log in
with the Attic client, and upload explicit closures with:

```fish
attic push dotfiles /run/current-system
```

Automatic store watching is not enabled; uploads remain deliberate.
