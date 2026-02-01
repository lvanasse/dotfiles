# Dotfiles Docs

This directory documents how this flake is structured and how to maintain it.

## Structure (Dendritic)

- `flake.nix` imports modules via flake-parts + import-tree.
- `modules/flake/` defines flake outputs (checks, overlays, lib, packages, formatter).
- `modules/nixos/` contains NixOS modules (core, desktop, services, programs).
- `modules/home/` contains Home Manager modules (core, desktop, programs, services, packages).
- `modules/hosts/` defines the host matrix (which module sets each host uses for both NixOS + HM).
- `nixos/` contains per-host NixOS entrypoints and hardware bits (e.g., `nixos/pc/pc.nix`).

## Host Matrix Naming

Hosts are defined as module lists in `modules/hosts/default.nix`.

- `profile.workstation` → shared system + HM baseline for all machines.
- `desktop.common` → common desktop stack (audio/fonts + GTK/XDG).
- `desktop.sway` → Sway-specific modules for both NixOS and Home Manager.
- `desktop.kde` → KDE/Plasma-specific modules for both NixOS and Home Manager.
- `host.pc` / `host.laptop` → host-only modules (hardware quirks, per-machine tweaks).

Laptop uses `host.laptop` (not `host.pc`).

Per-host system entrypoints live under `nixos/<host>/<host>.nix`; they import the host’s hardware and service files and are wired into the matrix via `flake.modules.nixos."host.<name>"`.

## Setup Guides

- `docs/setup-ssh-keys.md` – detailed SSH + secrets flow.
- `docs/remove-nix.md` – completely removing Nix from your system.
- `docs/install-home-manager.md` – installing Home Manager on non-NixOS systems (e.g., Ubuntu).

## Common Commands

```bash
# Switch NixOS host
nh os switch -H pc
nh os switch -H laptop

# Apply Home Manager
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@laptop
home-manager switch --flake .#ludovic@hm-only  # For non-NixOS systems

# Validate
nix flake check
nixos-rebuild dry-run --flake .#pc
nixos-rebuild dry-run --flake .#laptop

# Format
nix fmt
```
