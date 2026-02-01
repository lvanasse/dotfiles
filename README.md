# Personal NixOS Dotfiles

Flake-based NixOS + Home Manager configuration for desktop (`pc`), laptop (`laptop`), and Home Manager-only (`hm-only`).

## Quick Start

```bash
# Switch system configuration (NixOS hosts only)
nh os switch -H pc
nh os switch -H laptop

# Apply user environment
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@laptop
home-manager switch --flake .#ludovic@hm-only

# Validate
nix flake check
nixos-rebuild dry-run --flake .#pc
nixos-rebuild dry-run --flake .#laptop
# For hm-only (Home Manager only), test with:
nix eval .#homeConfigurations.ludovic@hm-only.config.home.stateVersion

# Format
nix fmt
```

## Documentation

- `docs/README.md` – structure + commands
- `docs/setup-ssh-keys.md` – SSH + secrets workflow

## Layout

- `flake.nix` – flake entrypoint
- `modules/` – shared module tree (flake outputs, NixOS, Home Manager, host matrix)
- `modules/hosts/` – host matrix declaring which module sets each machine uses
- `nixos/` – per-host NixOS entrypoints and hardware bits (e.g., `nixos/pc/pc.nix`)
- `wallpapers/` – desktop assets

Why both `modules/hosts` and `nixos/`?

- `modules/hosts/default.nix` is the matrix that maps host names to module sets for both NixOS and Home Manager.
- `nixos/<host>/<host>.nix` is the system entrypoint that pulls in hardware and per-machine files.
