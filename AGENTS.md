# Repository Guidelines

## Project Structure & Module Organization

- `flake.nix` – Flake entrypoint defining inputs/outputs and host configs.
- `nixos/` – Per-host NixOS entrypoints (e.g., `nixos/pc/pc.nix`, `nixos/laptop/laptop.nix`); do not edit `hardware-configuration.nix`.
- `modules/hosts/` – Host matrix (maps module sets to each host for NixOS + Home Manager).
- `modules/nixos/` – Shared NixOS modules.
- `modules/home/` – Shared Home Manager modules.
- `wallpapers/` – Desktop assets.

## Build, Test, and Development Commands

- Switch NixOS host: `nh os switch -H pc` (or `laptop`) — build and activate system.
- Apply Home Manager: `home-manager switch --flake .#ludovic@pc` — update user env.
- Format Nix: `nixfmt-rfc-style **/*.nix` — enforce consistent style.
- Update inputs: `nix flake update` — refresh and lock dependencies.

## Coding Style & Naming Conventions

- Indentation: 2 spaces (standard Nix formatting).
- Files: kebab-case for modules; `hostname.nix` for host configs.
- Variables: camelCase for Nix attributes; kebab-case for package names.
- Always run `nixfmt-rfc-style` before committing; keep changes minimal and modular.

## Testing Guidelines

- Manual testing only: verify builds evaluate and activate on target host(s).
- For shared changes, test both `pc` and `laptop`.
- Typical flow: edit → `nh os switch -H <host>` → `home-manager switch --flake .#ludovic@<host>` → verify runtime behavior.

## Commit & Pull Request Guidelines

- Commit format: `scope: brief description` (e.g., `pc: Enable flathub`, `home: Add Java support`).
- Scopes: `pc`, `laptop`, `home`, `modules`, `doc`, `fix`, `cleanup`.
- One logical change per commit. Note hosts tested and key commands run.
- After `nix flake update`, commit `flake.lock` to ensure reproducibility.

## Security & Configuration Tips

- Never hand-edit `hardware-configuration.nix`.
- SSH: root login disabled; password auth enabled per host config.
- Trusted users: `root`, `ludovic`. Firewall enabled (allowing port 59793 for torrenting).

## Agent Notes

- Keep patches focused; avoid unrelated edits. Respect existing structure and naming.
- When adding modules, wire imports in `nixos/<host>/<host>.nix` and test both hosts.
