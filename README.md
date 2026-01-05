# Personal NixOS Dotfiles

Flake-based NixOS + Home Manager configuration for desktop (pc) and laptop.

## Quick Start

```bash
# Switch system configuration
nh os switch -H pc
nh os switch -H laptop

# Apply user environment
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@laptop

# Validate
nix flake check
nixos-rebuild dry-run --flake .#pc
nixos-rebuild dry-run --flake .#laptop

# Format
nix fmt
```

## Documentation

- `docs/README.md` – structure + commands
- `docs/setup-ssh-keys.md` – SSH + secrets workflow

## Layout

- `flake.nix` – flake entrypoint
- `modules/` – dendritic module tree (flake outputs, NixOS, Home Manager, hosts)
- `hosts/` – host-only NixOS modules
- `wallpapers/` – desktop assets
