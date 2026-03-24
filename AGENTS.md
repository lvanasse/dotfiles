# Repository Guidelines

## Architecture

This repository uses a flake-based NixOS/Home Manager setup with `flake-parts` and `import-tree`.

Dendritic layout:
- `modules/` contains reusable modules that self-register under `flake.modules.*`.
- `hosts/` contains host-specific configs that are explicitly registered in `hosts/default.nix`.

Module naming patterns:
- `profile.*` for bundles (for example `profile.workstation`, `profile.server`)
- `desktop.*` for desktop stacks
- `services.*` for services
- `feature.*` for optional features
- `host.*` for host entrypoints

## Project Structure

- `flake.nix`: flake entrypoint and outputs wiring.
- `hosts/default.nix`: host matrix and module registration.
- `hosts/<host>/`: per-host NixOS entrypoint + Home Manager overrides.
- `modules/flake/`: custom lib/helpers, overlays, packages, checks, formatter.
- `modules/nixos/`: shared NixOS modules.
- `modules/home/`: shared Home Manager modules.
- `wallpapers/`: desktop assets.

## Build, Test, and Development Commands

- Switch NixOS host: `nh os switch -H pc` (or `laptop`, `server`).
- Apply Home Manager: `home-manager switch --flake .#ludovic@pc`.
- Unified switch script: `./scripts/nix-switch.sh <host>`.
- Validate: `nix flake check` and `nixos-rebuild dry-run --flake .#pc`.
- Format: `nix fmt` (or `nixfmt-rfc-style **/*.nix`).
- Update inputs: `nix flake update` and commit `flake.lock`.

## Coding Style & Naming

- Use 2-space indentation in Nix files.
- Use kebab-case filenames for modules.
- Use `hostname.nix` naming for host entrypoints.
- Use camelCase for Nix attributes and kebab-case package names.
- Keep changes minimal, modular, and focused.

## Testing Guidelines

- Manual testing only: evaluate and activate on target host(s).
- For shared changes, test both `pc` and `laptop` when applicable.
- Typical flow: edit -> `nh os switch -H <host>` -> `home-manager switch --flake .#ludovic@<host>` -> runtime verification.

## Adding Hosts and Services

Adding a host:
1. Create `hosts/<hostname>/` with `<hostname>.nix`, `home.nix`, and generated `hardware-configuration.nix`.
2. Register it in `hosts/default.nix` under both host matrix and `flake.modules.nixos/homeManager."host.<hostname>"`.

Adding a service module:
1. Create `modules/nixos/services/<service>.nix`.
2. Register as `flake.modules.nixos."services.<service>"`.
3. Include it from the relevant profile module.

## Commit Guidelines

- Use `scope: brief description` (for example `pc: enable flathub`, `home: add Java support`).
- Suggested scopes: `pc`, `laptop`, `server`, `home`, `modules`, `doc`, `fix`, `cleanup`.
- Keep one logical change per commit and note hosts tested + commands run.

## Security Notes

- Never hand-edit `hosts/*/hardware-configuration.nix`.
- SSH hardening and firewall settings are host-controlled; keep changes explicit and reviewable.

## Agent Notes

- Keep patches focused and avoid unrelated edits.
- Respect the `modules/` vs `hosts/` separation.
- When adding modules, ensure they are correctly wired through host/profile imports.
- Prefer Fish-compatible commands when giving the user shell snippets; if Bash syntax is required, say so explicitly and wrap it with `bash -lc`.
