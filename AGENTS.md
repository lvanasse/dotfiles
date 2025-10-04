# Repository Guidelines

## Project Structure & Module Organization

This NixOS dotfiles repository uses a modular flake-based structure:

- `hosts/` – Machine-specific NixOS configurations (pc, laptop)
- `home/` – Home Manager user environment configurations
- `modules/common/` – Shared NixOS modules (system, users, desktop, gaming)
- `flake.nix` – Main flake entrypoint with inputs and host definitions
- `wallpapers/` – Desktop wallpaper assets

## Build, Test, and Development Commands

```bash
# Switch NixOS system configuration
nh os switch -H pc
nh os switch -H laptop

# Apply Home Manager configuration separately
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@laptop

# Format Nix code
nixfmt-rfc-style **/*.nix

# Update flake inputs
nix flake update
```

## Coding Style & Naming Conventions

- **Indentation**: 2 spaces (standard Nix formatting)
- **File naming**: kebab-case for modules, hostname.nix for host configs
- **Variable naming**: camelCase for Nix attributes, kebab-case for package names
- **Formatting**: Use nixfmt-rfc-style for consistent code formatting

## Testing Guidelines

- **Framework**: Manual testing via system rebuilds and Home Manager switches
- **Validation**: Verify configurations build successfully before committing
- **Testing**: Test changes on both pc and laptop hosts when applicable

## Commit & Pull Request Guidelines

- **Commit format**: `scope: brief description` (e.g., "pc: Add flatpak services", "home: Add Java support")
- **Scope examples**: pc, laptop, home, modules, doc, fix, cleanup
- **Changes**: Keep commits focused on single logical changes
- **Testing**: Ensure configurations build before pushing

______________________________________________________________________

# Repository Tour

## 🎯 What This Repository Does

This repository is a NixOS dotfiles configuration managed as a Nix flake, providing reproducible system and user environment setups for two machines (pc and laptop).

**Key responsibilities:**

- System-wide NixOS configuration management
- User environment setup via Home Manager
- Development toolchain configuration (C/C++, Rust, Python, embedded development)

______________________________________________________________________

## 🏗️ Architecture Overview

### System Context

```
User → [NixOS Host Config] → [Common Modules] → [Hardware Config]
            ↓
    [Home Manager] → [User Packages & Config]
            ↓
    [Development Environment]
```

### Key Components

- **Flake System** - Centralized input management and host definitions
- **Host Configurations** - Machine-specific settings (pc.nix, laptop.nix)
- **Common Modules** - Shared system configuration (users, desktop environment, gaming)
- **Home Manager** - User-level package and configuration management

### Data Flow

1. Flake inputs define external dependencies (nixpkgs, home-manager, etc.)
1. Host configurations import common modules and hardware-specific settings
1. Home Manager applies user-level configurations and packages
1. System builds are applied via `nh os switch` or `nixos-rebuild`

______________________________________________________________________

## 📁 Project Structure [Partial Directory Tree]

```
dotfiles/
├── flake.nix                  # Main flake configuration with inputs/outputs
├── flake.lock                 # Locked dependency versions
├── hosts/                     # Machine-specific configurations
│   ├── pc/                    # Desktop workstation config
│   │   ├── pc.nix            # Main PC configuration
│   │   └── hardware-configuration.nix  # Hardware-specific settings
│   └── laptop/                # Laptop configuration
│       ├── laptop.nix        # Main laptop configuration
│       └── hardware-configuration.nix  # Hardware-specific settings
├── home/                      # Home Manager configurations
│   ├── default.nix           # Common user configuration
│   ├── pc.nix               # PC-specific user settings
│   └── laptop.nix           # Laptop-specific user settings
├── modules/common/            # Shared NixOS modules
│   ├── system.nix           # Base system configuration
│   ├── users.nix            # User account setup
│   ├── de.nix               # Desktop environment (currently empty)
│   └── gaming.nix           # Gaming-related configuration
├── wallpapers/               # Desktop wallpaper assets
└── README.md                 # Basic setup instructions
```

### Key Files to Know

| File | Purpose | When You'd Touch It |
|------|---------|---------------------|
| `flake.nix` | Main configuration entry point | Adding new inputs, creating new hosts |
| `hosts/pc/pc.nix` | PC-specific system config | PC hardware changes, PC-only services |
| `home/default.nix` | Common user environment | Adding packages, configuring programs |
| `modules/common/system.nix` | Base system settings | System-wide changes, fonts, services |
| `modules/common/users.nix` | User account configuration | User permissions, shell settings |
| `flake.lock` | Dependency lock file | After running `nix flake update` |

______________________________________________________________________

## 🔧 Technology Stack

### Core Technologies

- **Language:** Nix - Functional package manager and configuration language
- **Framework:** NixOS - Linux distribution built on Nix package manager
- **User Management:** Home Manager - User environment management for Nix
- **Build System:** Nix Flakes - Modern Nix project structure with dependency locking

### Key Libraries

- **nixpkgs** - Main package repository for Nix/NixOS
- **home-manager** - Declarative user environment management
- **plasma-manager** - KDE Plasma configuration via Home Manager
- **stylix** - System-wide theming (currently commented out)
- **nix-flatpak** - Flatpak integration for NixOS
- **nix-vscode-extensions** - VS Code extension management via Nix

### Development Tools

- **nh** - NixOS helper for easier system management
- **direnv** - Environment variable management per directory
- **nixfmt-rfc-style** - Nix code formatting
- **VS Code** - Primary editor with extensive extension configuration

______________________________________________________________________

## 🌐 External Dependencies

### Required Services

- **nixpkgs** - Package repository (github:NixOS/nixpkgs/nixos-25.05)
- **home-manager** - User environment management
- **Nix binary cache** - Package binary distribution

### Optional Integrations

- **Flatpak** - Additional application distribution via flathub
- **OpenVPN** - VPN connectivity (configured for specific server)
- **Tailscale** - Mesh networking (currently disabled)

### Environment Variables

```bash
# Development environment
NPM_CONFIG_PREFIX=~/.npm-global    # npm global package location
PYENV_ROOT=~/.pyenv               # Python version management
POWERDEVIL_NO_DDCUTIL=1           # Disable DDC utilities for power management

# Build-time variables
VISUAL=vim                        # Default visual editor
EDITOR=vim                        # Default command-line editor
```

______________________________________________________________________

## 🔄 Common Workflows

### System Configuration Update

1. Edit configuration files in appropriate host or module directory
1. Test build: `nh os switch -H <hostname>`
1. Verify system functionality
1. Commit changes with descriptive message

**Code path:** `flake.nix` → `hosts/<hostname>/<hostname>.nix` → `modules/common/*.nix`

### Adding New Packages

1. Add package to `home/default.nix` in `home.packages` list
1. Apply changes: `home-manager switch --flake .#ludovic@<hostname>`
1. Test package functionality
1. Commit changes

**Code path:** `home/default.nix` → Home Manager → User environment

### Development Environment Setup

1. Configure development tools in `home/default.nix`
1. Add VS Code extensions in `programs.vscode.profiles.default.extensions`
1. Set up language-specific tools (Java, Rust, Python via pyenv)
1. Apply via Home Manager switch

**Code path:** `home/default.nix` → VS Code config → Development environment

______________________________________________________________________

## 📈 Performance & Scale

### Performance Considerations

- **Nix store optimization** - Automatic store optimization enabled
- **Garbage collection** - Weekly automatic cleanup, keeping 5 generations
- **Lazy evaluation** - Nix's lazy evaluation reduces memory usage
- **Binary caches** - Pre-built packages reduce compilation time

### Monitoring

- **System resources** - btop, htop, nvtop for monitoring
- **Build times** - nh provides build progress and timing
- **Storage usage** - Automatic Nix store optimization and garbage collection

______________________________________________________________________

## 🚨 Things to Be Careful About

### 🔒 Security Considerations

- **Trusted users** - Root and ludovic have Nix trusted user privileges
- **SSH access** - Password authentication enabled, root login disabled
- **Firewall** - Enabled with specific port allowances (59793 for torrenting)
- **Flatpak** - Additional attack surface through Flatpak applications

### Development Workflow Cautions

- **Hardware configurations** - Never edit hardware-configuration.nix manually
- **Flake lock** - Commit flake.lock changes to ensure reproducibility
- **System testing** - Always test configuration changes before committing
- **Backup considerations** - NixOS generations provide rollback capability

*Update to last commit: 41936868f8a1c022041be66b028f7e626c018479*
