# Tachyon webmail on server

Tachyon is declared in `modules/nixos/services/tachyon.nix` and imported only by
the server target. It uses the official v4.4.2 image pinned to its linux/amd64
digest and persists `/var/lib/tachyon` at
`/mnt/ssd/appdata/docker/tachyon`. Back up that entire directory, including
`SALT.php`: losing the salt can invalidate encrypted settings and TOTP secrets.
No IMAP, SMTP, CalDAV, or CardDAV credentials are committed to this repository.
The app collects account credentials through its login and settings screens and
stores them in the restricted data directory. The existing agenix mail and
calendar secrets are not mounted into the container.

The NixOS module mounts a read-only Gruvbox Dark Hard stylesheet as a custom
Tachyon theme and applies it to all accounts. Once Sent, Drafts, and Trash are
mapped as system folders, its CSS shows only those folders and Inbox in the
mail sidebar. The other folders remain on Infomaniak and are available in the
folder settings; the CSS does not reduce IMAP requests to those folders. The
message list has a direct read/unread toggle when messages are selected. It
uses Tachyon's existing IMAP action, so Android and other clients see the same
flag. `q` and `u` remain available as keyboard shortcuts; `?` opens Tachyon's
shortcut help.

The folder polling limit is four, so with more than four folders Tachyon checks
unread counts only for system folders and folders explicitly marked for checks.
This reduces background IMAP work, but Tachyon still fetches a folder's message
list when it is opened.

## Network and Cloudflare

The container publishes HTTP only on `172.17.0.1:8877`, the host's Docker
bridge address. The existing `cloudflared` container can reach it at
`http://172.17.0.1:8877`; no LAN or WAN firewall port is opened. Before adding
the public route, create a Cloudflare Access self-hosted application for
`email.ludovicvanasse.com` with an Allow policy restricted to the intended
identity and a 30-day application session. Add the hostname to the existing
tunnel with the origin URL above and enable **Protect with Access** for the
route. An anonymous request must get the Access sign-in page and must not reach
Tachyon's login. Cloudflare Access expires after 30 days, so reauthentication
is required even on a remembered machine.

## First login

1. Open `https://email.ludovicvanasse.com/?admin`. The first visit creates
   `/var/lib/tachyon/_data_/_default_/admin_password.txt` inside the container.
   Read it on the server without copying it into logs or
   shell history. Sign in as `admin`, replace the initial password, and enable
   admin TOTP. Tachyon removes the initial password file after the change.
2. The server setup creates the `ludovicvanasse.com` domain profile on first
   activation: IMAP `mail.infomaniak.com:993` with TLS, SMTP
   `mail.infomaniak.com:587` with STARTTLS, authentication and certificate
   verification enabled. It does not overwrite later admin UI edits. Use the
   full email address to log in and test both connections in Tachyon.
3. Verify that the Calendar entry appears and contacts sync is available.
   The NixOS `tachyon-configure.service` enables `[calendar]` and `[contacts]`
   `enable` and `allow_sync` after the app creates its config. Leave both
   storage backends on their SQLite defaults; no separate database is needed.
   Do not disable server certificate verification.
4. Sign in with the Infomaniak mailbox address and its application password.
   In **Settings → Folders**, map the provider's existing special folders
   rather than creating replacements. The existing client uses `Index` for
   inbox, `Sent`, `Drafts`, and `Trash`; confirm those names in the live mailbox.
   IMAP owns read/unread flags and folder contents, so Android continues to
   connect directly to Infomaniak.
5. In **Settings → Calendar**, use `https://sync.infomaniak.com`, the
   Infomaniak DAV username from its synchronization assistant (an account ID,
   not necessarily the mailbox address), and its application password, then press **Test**
   and select the discovered calendars. If discovery fails, use the account's
   calendar-home URL from Infomaniak. Set up CardDAV in the contacts settings
   using `https://sync.infomaniak.com` and the same DAV account credentials;
   test a contact in each direction.

The local plugin adds OpenStreetMap location suggestions and a display-reminder
field. Reminders are written as iCalendar `VALARM` blocks; verify that
Infomaniak preserves them during a round trip before relying on them. Tachyon
still does not support task lists or invitation responses. Verify creation,
editing, deletion, reminders, and two-way sync with a disposable non-recurring
event before relying on the calendar.

## Operations

Check `docker-tachyon.service`, the container's status and logs, the bind
address, and `http://172.17.0.1:8877/` after deployment. Also test the public
hostname without an Access session and from an authenticated browser. To
upgrade, review an upstream release, change both version and image digest in
the NixOS module, evaluate and deploy the server target, then repeat mail/DAV
checks. The repository's automatic container updater excludes Tachyon because
the deployment is digest-pinned. Restore the appdata directory as one unit if
rolling back user data; avoid mixing data from different snapshots.

The official image starts its supervisor, nginx master, and PHP-FPM master as
root and uses unprivileged workers. Its entrypoint edits runtime config and
changes data ownership, so running the whole image as a non-root UID or with
a read-only root filesystem is not currently supported. The NixOS module drops
all capabilities except those needed for startup file access, ownership, and UID changes,
sets `no-new-privileges`, and gives it one persistent mount.

Upstream: [installation](https://github.com/kimusan/Tachyon/wiki/Installation-instructions),
[Docker](https://github.com/kimusan/Tachyon/wiki/Docker),
[calendar](https://github.com/kimusan/Tachyon/wiki/Calendar),
[admin settings](https://github.com/kimusan/Tachyon/wiki/Admin-Manual).
