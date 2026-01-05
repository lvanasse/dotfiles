# SSH Keys + Secrets Setup

This repo expects two SSH keys (personal + work) and stores them in the private
`secrets` repo. NixOS deploys them via agenix and Home Manager configures SSH
host aliases (GitHub/Bitbucket/Codeberg).

## Expected Files (in the secrets repo)

```
keys/id_ed25519_personal.pub
keys/id_ed25519_work.pub
ssh/id_ed25519_personal.age
ssh/id_ed25519_work.age
```

If these are missing, the config will skip deployment (it checks `pathExists`).

## 1) Bootstrap Access (new machine)

You must be able to fetch the private secrets repo:

- If you already have keys: copy them temporarily into `~/.ssh/` and set perms.
- If you don’t: generate new keys (next section), add them to Codeberg/GitHub/Bitbucket,
  then continue.

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

## 2) Generate or Restore Keys

Generate new keys (or restore from backup):

```bash
# Personal key
ssh-keygen -t ed25519 -C "mail@ludovicvanasse.com" -f ~/.ssh/id_ed25519_personal

# Work key
ssh-keygen -t ed25519 -C "lvanasse@luxaerobot.com" -f ~/.ssh/id_ed25519_work
```

Ensure permissions:

```bash
chmod 600 ~/.ssh/id_ed25519_personal ~/.ssh/id_ed25519_work
chmod 644 ~/.ssh/id_ed25519_personal.pub ~/.ssh/id_ed25519_work.pub
```

## 3) Add Public Keys to Git Hosts

- GitHub (personal): add `id_ed25519_personal.pub`
- Bitbucket (work): add `id_ed25519_work.pub`
- Codeberg (personal): add `id_ed25519_personal.pub` (needed to fetch secrets repo)

## 4) Add Keys to the Secrets Repo (agenix)

If you generated new keys, update the secrets repo:

1. Put public keys in `keys/`.
1. Encrypt private keys into `ssh/` as `.age` files.
1. Re-key for the target host so it can decrypt.

Example flow (inside the secrets repo):

```bash
# Add public keys
cp ~/.ssh/id_ed25519_personal.pub keys/
cp ~/.ssh/id_ed25519_work.pub keys/

# Encrypt private keys (example using agenix)
agenix -e ssh/id_ed25519_personal.age -i ~/.ssh/id_ed25519_personal
agenix -e ssh/id_ed25519_work.age -i ~/.ssh/id_ed25519_work

# Re-encrypt all secrets for this host (requires its SSH host key in secrets.nix)
agenix -r
```

## 5) Apply the Configuration

```bash
nh os switch -H pc   # or laptop
home-manager switch --flake .#ludovic@pc   # or laptop
```

The system will deploy keys to:

- `~/.ssh/id_ed25519_personal`
- `~/.ssh/id_ed25519_work`

## 6) Test Connections

```bash
# Personal GitHub
ssh -T github-personal

# Work Bitbucket
ssh -T bitbucket-work

# Codeberg (personal)
ssh -T git@codeberg.org
```

## Notes on SSH Agent

This setup disables the legacy `ssh-agent` and relies on gnome-keyring/gcr for
agent support. If keys are not being offered:

```bash
systemctl --user status gnome-keyring-daemon
ssh-add -L
```

## Troubleshooting

- `Permission denied (publickey)` → key not loaded or not added to the host.
- `Could not resolve hostname github-personal` → SSH config not applied; re-run HM.
- `No matching host key` during decryption → add the host SSH key to secrets and rekey.
- `Bad permissions` → ensure `~/.ssh` is 700 and private keys are 600.
