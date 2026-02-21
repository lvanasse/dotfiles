# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a flake-based NixOS configuration using **flake-parts** and **import-tree** for automatic module discovery. The repository manages both system-level (NixOS) and user-level (Home Manager) configurations following a **dendritic pattern**.

### Dendritic Design

- **modules/**: Reusable building blocks (auto-imported via import-tree)
- **hosts/**: Host-specific configurations (explicitly imported)

This separation keeps reusable code decoupled from specific machines.

### Module System

Modules self-register in the `flake.modules.nixos.*` or `flake.modules.homeManager.*` namespaces:

```nix
{ config, ... }:
{
  flake.modules.nixos."desktop.sway" = { pkgs, ... }: {
    # NixOS system configuration
  };
}
```

Module naming convention:
- `profile.*`: Bundles (profile.workstation, profile.server)
- `desktop.*`: Desktop environments (desktop.sway, desktop.kde)
- `services.*`: Services (services.docker, services.jellyfin)
- `feature.*`: Optional features (feature.steam)

### Directory Structure

```
modules/                    # Reusable modules (auto-imported)
├── flake/                  # Flake outputs (lib, overlays, packages, checks)
├── nixos/                  # NixOS modules
│   ├── core/              # Base system (nix, locale, networking, users)
│   ├── desktop/           # Desktop environments
│   ├── services/          # System services (docker, ssh, jellyfin, arr, etc.)
│   ├── programs/          # System programs
│   └── server/            # Server profile definition
└── home/                   # Home Manager modules
    ├── core.nix           # Base HM settings
    ├── desktop/           # Desktop configs (gtk, sway, plasma)
    ├── programs/          # Program configs (git, firefox, emacs, etc.)
    ├── packages/          # Package groups
    └── server.nix         # Server HM profile

hosts/                      # Host-specific configs (explicitly imported)
├── default.nix            # Host matrix (central registry)
├── pc/
│   ├── pc.nix             # NixOS entrypoint
│   ├── home.nix           # HM overrides
│   ├── hardware-configuration.nix
│   └── ...
├── laptop/
│   ├── laptop.nix
│   ├── home.nix
│   ├── disko.nix          # Disk partitioning
│   └── ...
├── server/
│   ├── server.nix
│   ├── home.nix
│   └── disko.nix
├── hm-only/               # Non-NixOS host
│   └── home.nix
└── steamdeck/
    └── home.nix
```

### Host Configuration Pattern

Hosts are defined in `hosts/default.nix`:

```nix
hosts = {
  pc = {
    nixos = true;
    modules = [
      "profile.workstation"
      "desktop.sway"
      "desktop.kde"
      "feature.steam"
      "host.pc"
    ];
  };
  server = {
    nixos = true;
    modules = [
      "profile.server"
      "host.server"
    ];
  };
};
```

Host modules are registered in the same file:
```nix
flake.modules.nixos."host.pc" = ./pc/pc.nix;
flake.modules.homeManager."host.pc" = ./pc/home.nix;
```

### Custom Library Functions

Located in `modules/flake/lib.nix`:

- `config.flake.lib.username`: Default username ("ludovic")
- `getModules`: Resolves module names to actual module paths
- `mkNixosConfiguration`: Creates NixOS system with integrated Home Manager
- `mkHomeConfiguration`: Creates standalone Home Manager config

## Common Commands

### Build and Deploy

```bash
# NixOS system switch
nh os switch -H pc
nh os switch -H laptop
nh os switch -H server

# Home Manager switch
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@hm-only

# Unified script (recommended)
./scripts/nix-switch.sh pc
./scripts/nix-switch.sh laptop
./scripts/nix-switch.sh hm-only
```

### Validation

```bash
nix flake check                      # Run all checks
nixos-rebuild dry-run --flake .#pc   # Preview changes
```

### Formatting

```bash
nix fmt                              # Format all Nix files
```

## Adding a New Host

1. Create directory: `hosts/<hostname>/`
   - `<hostname>.nix` (NixOS entrypoint)
   - `home.nix` (HM overrides, plain module format)
   - `hardware-configuration.nix` (generated)
   - Optional: `disko.nix`, `hardware.nix`, etc.

2. Register in `hosts/default.nix`:
   ```nix
   # In hosts definition
   <hostname> = {
     nixos = true;
     modules = [ "profile.workstation" "host.<hostname>" ];
   };

   # Module registration
   flake.modules.nixos."host.<hostname>" = ./<hostname>/<hostname>.nix;
   flake.modules.homeManager."host.<hostname>" = ./<hostname>/home.nix;
   ```

## Adding a New Service

Create `modules/nixos/services/<service>.nix`:
```nix
{ ... }:
{
  flake.modules.nixos."services.<service>" =
    { ... }:
    {
      # Service configuration
    };
}
```

Then import in a profile (e.g., `modules/nixos/server/default.nix`).

## Key Files

- `flake.nix`: Flake definition (imports modules/ and hosts/default.nix)
- `hosts/default.nix`: Host matrix and module registration
- `modules/flake/lib.nix`: Helper functions and overlays
- `modules/nixos/default.nix`: profile.workstation definition
- `modules/nixos/server/default.nix`: profile.server definition
- `modules/home/default.nix`: HM profile.workstation definition

## NixOS vs Home Manager

**NixOS modules** (`modules/nixos/`): System-level (requires root)
- kernel, boot, system services, hardware, networking

**Home Manager modules** (`modules/home/`): User-level (no root)
- dotfiles, user packages, program configs, user services

Many features have both components activated from the same module name.

## Server Configuration

The server profile includes:
- Docker for containers
- Services: jellyfin, arr stack (sonarr, radarr, etc.), nextcloud, vaultwarden, cloudflared
- Storage: snapraid + mergerfs for disk pooling
- SSH access, tailscale

## Secrets Management

Uses **agenix** for encrypted secrets. See `docs/setup-ssh-keys.md`.

## Disk Partitioning

Uses **disko** for declarative partitioning. See `hosts/laptop/disko.nix` or `hosts/server/disko.nix`.
