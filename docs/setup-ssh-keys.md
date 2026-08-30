# SSH Keys + Secrets Setup

This repo can deploy two SSH keys (personal + work) from the private `secrets`
repo. NixOS targets deploy them via agenix, and Home Manager configures SSH host
aliases (GitHub/Bitbucket/Codeberg).

The personal key is the shared key used for personal GitHub and Codeberg pushes.
The work key is optional until `keys/id_ed25519_work.pub` and
`ssh/id_ed25519_work.age` exist in the secrets repo.

## Expected Files (in the secrets repo)

```
keys/id_ed25519_personal.pub
ssh/id_ed25519_personal.age

# Optional work key support
keys/id_ed25519_work.pub
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

### Home Manager-only targets

`work-laptop` cannot rely on `~/.ssh/id_ed25519_personal` to decrypt
`ssh/id_ed25519_personal.age` during first activation because that file is also
the deployed secret output. Keep a persistent bootstrap age identity at:

```bash
~/.ssh/id_ed25519_work_laptop_bootstrap
```

On `work-laptop`, identify the private key matching
`keys/work_laptop_personal.pub` in the secrets repo. If it exists, install it as
the bootstrap identity:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp /path/to/private/bootstrap/key ~/.ssh/id_ed25519_work_laptop_bootstrap
chmod 600 ~/.ssh/id_ed25519_work_laptop_bootstrap
```

If that private key is not recoverable, generate a new bootstrap key and replace
`keys/work_laptop_personal.pub` in the secrets repo:

```bash
ssh-keygen -t ed25519 -C "work-laptop bootstrap" -f ~/.ssh/id_ed25519_work_laptop_bootstrap
chmod 600 ~/.ssh/id_ed25519_work_laptop_bootstrap
chmod 644 ~/.ssh/id_ed25519_work_laptop_bootstrap.pub
cp ~/.ssh/id_ed25519_work_laptop_bootstrap.pub keys/work_laptop_personal.pub
```

Then rekey the secrets repo before evaluating or activating the Home Manager
configuration:

```bash
agenix -r
```

## 2) Generate or Restore Keys

Generate new Git host keys only if the existing private keys are unrecoverable.
Otherwise, restore the current private keys from backup:

```bash
# Personal key
ssh-keygen -t ed25519 -C "mail@ludovicvanasse.com" -f ~/.ssh/id_ed25519_personal

# Work key (only when restoring or creating work-key support)
ssh-keygen -t ed25519 -C "lvanasse@luxaerobot.com" -f ~/.ssh/id_ed25519_work
```

Ensure permissions:

```bash
chmod 600 ~/.ssh/id_ed25519_personal
chmod 644 ~/.ssh/id_ed25519_personal.pub

# If the work key exists:
chmod 600 ~/.ssh/id_ed25519_work
chmod 644 ~/.ssh/id_ed25519_work.pub
```

## 3) Add Public Keys to Git Hosts

- GitHub (personal): add `id_ed25519_personal.pub`
- Bitbucket (work): add `id_ed25519_work.pub`
- Codeberg (personal): add `id_ed25519_personal.pub` (needed to fetch secrets repo)

## 4) Add Keys to the Secrets Repo (agenix)

If you generated or restored keys, update the secrets repo:

1. Put public keys in `keys/`.
1. Encrypt private keys into `ssh/` as `.age` files.
1. Re-key for every target identity that must decrypt them.

Example flow (inside the secrets repo):

```bash
# Add public keys.
cp ~/.ssh/id_ed25519_personal.pub keys/

# If the work key exists:
cp ~/.ssh/id_ed25519_work.pub keys/

# Encrypt private keys.
agenix -e ssh/id_ed25519_personal.age -i ~/.ssh/id_ed25519_personal

# If the work key exists:
agenix -e ssh/id_ed25519_work.age -i ~/.ssh/id_ed25519_work

# Re-encrypt all secrets for the configured identities.
agenix -r
```

Make sure `ssh/id_ed25519_personal.age` is encrypted to the `pc`, `laptop`,
`admin`, and `work-laptop` bootstrap identities. Do not rely on
`~/.ssh/id_ed25519_personal` as the only `work-laptop` age identity because it
is replaced by the deployed personal key.

## 5) Apply the Configuration

```bash
nh os switch -H pc   # or laptop
home-manager switch --flake .#ludovic@pc   # or laptop

# Home Manager-only work laptop
home-manager switch --flake .#ludovic@work-laptop
```

The system will deploy keys to:

- `~/.ssh/id_ed25519_personal`
- `~/.ssh/id_ed25519_work` if the work secret exists

## 6) Test Connections

```bash
# Personal GitHub
ssh -T github-personal

# Work Bitbucket
ssh -T bitbucket-work

# Codeberg (personal)
ssh -T git@codeberg.org
```

In personal repositories, GitHub remotes are rewritten to `github-personal` by
the `gitdir:~/Code/personal/` include. Check a repository with:

```bash
git remote -v
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
