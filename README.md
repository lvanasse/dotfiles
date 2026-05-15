# Personal Dotfiles

Flake-based NixOS and Home Manager configuration for a small set of machines and user-only targets.

## Targets

- NixOS: `pc`, `laptop`, `server`, `gateway`
- Home Manager only: `hm-only`, `work-laptop`, `steamdeck`

The target matrix lives in [targets/default.nix](targets/default.nix). Each target registers one NixOS entrypoint, one Home Manager entrypoint, or both.

## Common Commands

```bash
# Unified host switch
nohm pc
nohm laptop
nohm server
nohm gateway

# Plain NixOS switch
nh os switch -H pc

# Plain Home Manager switch
home-manager switch --flake .#ludovic@pc

# Validate
nix flake check
nixos-rebuild dry-run --flake .#pc

# Format
nix fmt
```

## Structure

- `flake.nix`: inputs and top-level outputs wiring
- `targets/`: target registration plus per-target `nixos.nix` and `hm.nix` entrypoints
- `modules/nixos/`: shared NixOS modules
- `modules/home/`: shared Home Manager modules
- `modules/flake/`: overlays, helpers, checks, formatter, custom package wiring
- `overrides/`: local runtime/config override files used by services
- `wallpapers/`: desktop assets

## Conventions

- Reusable modules live under `modules/`
- Target-specific composition lives under `targets/`
- NixOS modules are exposed as `flake.modules.nixos.*`
- Home Manager modules are exposed as `flake.modules.homeManager.*`

This repository is meant to be edited in small, target-scoped changes and validated on the machine that will actually consume them.
