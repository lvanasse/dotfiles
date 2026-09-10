# Wealthsimple Cash and Credit Card to Actual bootstrap

The timer is intentionally disabled in `targets/server/nixos.nix`. The importer
uses Wealthsimple's unsupported private API, validates the complete Cash and
Credit Card responses, and refuses to call Actual when it encounters an unknown
status, currency, or activity shape.

## Secrets

Create `server/actual-wealthsimple.env.age` in the private secrets repository
from the matching section in `docs/server/secrets.env.example`, then encrypt it
with the repository's normal agenix workflow. The file is decrypted as root-only;
systemd reads it before changing to the dedicated service user. Wealthsimple's
password and TOTP seed must never be added: only the rotating OAuth session is
stored under `/var/lib/wealthsimple-actual-sync`.

## Controlled first import

After deploying without enabling the timer, use a root shell on the server. The
authentication command is Bash syntax because `systemd-run --pty` is used to
attach the interactive login to the service account:

```bash
bash -lc 'sudo systemd-run --quiet --wait --collect --pty \
  --uid=wealthsimple-actual-sync --gid=wealthsimple-actual-sync \
  --property=StateDirectory=wealthsimple-actual-sync \
  --setenv=PATH=/run/current-system/sw/bin \
  --setenv=WEALTHSIMPLE_CURL=/run/current-system/sw/bin/curl_chrome142 \
  /run/current-system/sw/bin/wealthsimple-actual-sync auth'

sudo systemctl start wealthsimple-actual-sync-list-wealthsimple-accounts.service
sudo systemctl start wealthsimple-actual-sync-create-actual-accounts.service
sudo systemctl start wealthsimple-actual-sync-stage.service
sudo systemctl start wealthsimple-actual-sync-dry-run.service
```

Read each result with `journalctl -u <unit> --no-pager`. The encrypted file must
map `WEALTHSIMPLE_ACCOUNT_ID` and `ACTUAL_ACCOUNT_ID` to the Cash accounts, and
`WEALTHSIMPLE_CREDIT_CARD_ACCOUNT_ID` and `ACTUAL_CREDIT_CARD_ACCOUNT_ID` to the
Credit Card accounts. The account-creation unit is idempotent and creates both
Actual accounts on-budget with zero opening balances.

Export and back up the Actual budget. Review counts, transaction signs, dates,
payees, and the opening balance. Explicitly authorize the first live import,
then run `sudo systemctl start wealthsimple-actual-sync.service` twice and require
the second reconciliation to add zero transactions in both accounts. Reconcile
the opening balances on the day before the 90-day cutoff manually; the importer
never creates or changes starting-balance transactions.

Only after those checks should `services.wealthsimpleActualSync.timer.enable` be
set to `true`. Inspect it with `systemctl list-timers wealthsimple-actual-sync.timer`.
An exit status of 20 means the rotating OAuth session can no longer refresh;
rerun `auth`. Other failures require inspecting
`journalctl -u wealthsimple-actual-sync.service` before retrying.
