# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a flake-based NixOS configuration using **flake-parts** and **import-tree** for automatic module discovery. The repository manages both system-level (NixOS) and user-level (Home Manager) configurations.

### Module System

Modules self-register in the `flake.modules.nixos.*` or `flake.modules.homeManager.*` namespaces using dotted naming:

```nix
{ config, ... }:
{
  flake.modules.nixos."desktop.sway" = { pkgs, ... }: {
    # NixOS system configuration
  };
}
```

Module naming convention:
- `profile.*` (bundles): `profile.workstation` combines core + desktop + services + programs
- `desktop.*`: `desktop.sway`, `desktop.kde`, `desktop.common`
- `feature.*`: Optional features like `feature.steam`
- `host.*`: Host-specific configs like `host.pc`, `host.laptop`

### Directory Structure

```
modules/
├── flake/              # Outputs (lib, overlays, packages, checks, formatter)
├── hosts/default.nix   # Host matrix (central registry mapping hosts to module lists)
├── nixos/              # NixOS system modules (core, desktop, programs, services)
└── home/               # Home Manager user modules (packages, programs, services, desktop)

nixos/
├── pc/                 # PC-specific system configuration
│   ├── pc.nix         # Host entrypoint (imports hardware + services + programs)
│   ├── hardware-configuration.nix  # Generated (DO NOT EDIT)
│   ├── hardware.nix
│   ├── networking.nix
│   ├── services.nix
│   ├── packages.nix
│   └── torrenting.nix
└── laptop/
    ├── laptop.nix
    ├── hardware-configuration.nix
    ├── hardware.nix
    └── disko.nix       # Declarative disk partitioning
```

### Host Configuration Pattern

Hosts are defined in `modules/hosts/default.nix`:

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
};
```

This generates:
- `nixosConfigurations.pc` (NixOS system config)
- `homeConfigurations.ludovic@pc` (Home Manager user config)

Both NixOS and Home Manager modules are activated from the same module list. Many features have dual implementations (e.g., `desktop.sway` has both system and user components).

### Custom Library Functions

Located in `modules/flake/lib.nix`:

- `config.flake.lib.username`: Default username ("ludovic")
- `getModules`: Resolves module names to actual module paths
- `mkNixosConfiguration`: Creates NixOS system with integrated Home Manager
- `mkHomeConfiguration`: Creates standalone Home Manager config (for non-NixOS systems)

Overlays: `codexFromUnstable`, `qbittorrent510_2505`, `sonarlintHashFix`, plus emacs-overlay, nix-vscode-extensions, nixgl.

## Common Commands

### Build and Deploy

**NixOS system switch:**
```bash
nh os switch -H pc
nh os switch -H laptop
```

**Home Manager switch:**
```bash
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@laptop
home-manager switch --flake .#ludovic@hm-only  # Non-NixOS systems
```

**Unified script (recommended):**
```bash
./scripts/nix-switch.sh pc      # Runs HM switch + NixOS switch
./scripts/nix-switch.sh laptop
./scripts/nix-switch.sh hm-only # HM only + symlinks wayland sessions
```

### Validation and Testing

```bash
nix flake check                      # Run all checks
nixos-rebuild dry-run --flake .#pc   # Preview NixOS changes
nixos-rebuild dry-run --flake .#laptop
```

### Formatting

```bash
nix fmt                  # Format all Nix files (uses nixfmt-rfc-style)
```

### Updating Dependencies

```bash
nix flake update         # Update flake.lock
```

## Adding a New Host

1. Create NixOS configuration directory: `nixos/<hostname>/`
   - `<hostname>.nix` (imports hardware-configuration.nix + other files)
   - `hardware-configuration.nix` (generated via `nixos-generate-config`)
   - Optional: `hardware.nix`, `networking.nix`, `services.nix`, etc.

2. Create host-specific Home Manager module (optional): `modules/home/hosts/<hostname>.nix`

3. Register NixOS module in a module file:
   ```nix
   { ... }:
   {
     flake.modules.nixos."host.<hostname>" = ../../nixos/<hostname>/<hostname>.nix;
   }
   ```

4. Add host to `modules/hosts/default.nix`:
   ```nix
   hosts = {
     <hostname> = {
       nixos = true;  # or false for Home Manager-only
       modules = [
         "profile.workstation"
         "desktop.sway"
         "host.<hostname>"
       ];
     };
   };
   ```

5. For standalone Home Manager hosts (non-NixOS): set `nixos = false`.

## Creating a New Profile

Profiles bundle multiple modules. To create `profile.server`:

**NixOS side** (`modules/nixos/default.nix`):
```nix
flake.modules.nixos."profile.server" = { ... }: {
  imports = [
    config.flake.modules.nixos.core
    # Add server-specific modules
  ];
};
```

**Home Manager side** (`modules/home/default.nix`):
```nix
flake.modules.homeManager."profile.server" = { ... }: {
  imports = [
    config.flake.modules.homeManager.core
    # Add server-specific modules
  ];
};
```

Then reference in host matrix: `modules = ["profile.server" "host.server"];`

## Module Discovery

**import-tree** automatically imports all `.nix` files in `modules/`. Adding a new module requires:
1. Create file in appropriate subdirectory (e.g., `modules/nixos/programs/newprogram.nix`)
2. Define module namespace (e.g., `flake.modules.nixos."program.newprogram"`)
3. Reference in host matrix or profile

No manual imports needed in `flake.nix`.

## Key Files

- `flake.nix`: Main flake definition with inputs
- `modules/hosts/default.nix`: Host matrix (central registry)
- `modules/flake/lib.nix`: Custom helper functions and overlays
- `modules/nixos/default.nix`: NixOS workstation profile
- `modules/home/default.nix`: Home Manager workstation profile
- `modules/home/core.nix`: Base HM settings (username, homeDirectory, stateVersion)
- `modules/nixos/core/`: Base system settings (nix config, locale, networking, users)
- `nixos/pc/pc.nix`: PC system entrypoint
- `nixos/laptop/laptop.nix`: Laptop system entrypoint
- `scripts/nix-switch.sh`: Unified switch script for NixOS + HM

## NixOS vs Home Manager

**NixOS modules** (`modules/nixos/`):
- System-level configuration (requires root)
- Manages: kernel, boot, services, system packages, hardware, networking
- Examples: Desktop environment system parts (Sway program, KDE services), audio (PipeWire), fonts

**Home Manager modules** (`modules/home/`):
- User-level configuration (no root required)
- Manages: user packages, dotfiles, program configs, user services
- Examples: Sway WM config, application settings (VSCode, Firefox, Git), themes

Many features have both components. Including `"desktop.sway"` in a host activates both the NixOS system module and the Home Manager user module.

## Non-NixOS Support

The `hm-only` host demonstrates using this repository on non-NixOS systems (Ubuntu, etc.) via standalone Home Manager. Set `nixos = false` in the host definition.

`scripts/nix-switch.sh` handles non-NixOS systems by symlinking Wayland session files for GDM and configuring PAM for swaylock.

## Documentation

- `docs/README.md`: Structure and commands
- `docs/setup-ssh-keys.md`: SSH and secrets workflow (agenix)
- `docs/install-home-manager.md`: Installing Home Manager on non-NixOS systems
- `docs/remove-nix.md`: Removing Nix from system

## Secrets Management

Uses **agenix** for encrypted secrets. See `docs/setup-ssh-keys.md` for SSH key and secrets workflow.

## Disk Partitioning

Laptop uses **disko** for declarative disk partitioning (`nixos/laptop/disko.nix`). See disko configuration for automated disk setup patterns.
