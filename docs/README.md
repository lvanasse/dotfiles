# Personal NixOS Dotfiles Documentation

This is your personal NixOS configuration documentation. Everything here is organized to help you understand and maintain your setup.

## 📁 What's Where

### 🏗️ Architecture & Structure

- **[Repository Overview](architecture/repository-overview.md)** - Complete breakdown of your repository structure, technology stack, and how everything fits together
- **[Configuration Organization](architecture/configuration-organization.md)** - Details about the modular structure you implemented (the big reorganization from monolithic files)

### 🛠️ Development & Maintenance

- **[Tooling Guide](development/tooling.md)** - All the commands and tools you set up (nix fmt, flake checks, development shells, etc.)
- **[Improvements History](development/improvements.md)** - What you've implemented and what you were considering for the future

### 📖 Setup Guides

- **[SSH Keys Setup](guides/setup-ssh-keys.md)** - How to set up your personal/work Git SSH keys (you'll need this on new machines)

## 🚀 Quick Reference

### Daily Commands

```bash
# Switch system configuration
nh os switch -H pc        # For your desktop
nh os switch -H laptop    # For your laptop

# Apply user environment changes
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@laptop

# Development workflow
nix develop              # Enter dev environment with all tools
nix fmt                  # Format all code
nix flake check         # Validate everything builds
nix flake update        # Update all dependencies
```

### When You Break Something

```bash
# Check what's wrong
nix flake check

# See what would change before applying
nixos-rebuild dry-run --flake .#pc

# Roll back if needed (NixOS keeps old generations)
sudo nixos-rebuild switch --rollback
```

## 🎯 Your Setup Highlights

- **Two Machines**: PC (desktop) and laptop configurations
- **Modular Structure**: Everything is organized into focused modules instead of giant files
- **Work/Personal Git**: Automatic switching between your personal and work Git accounts based on directory
- **Development Tools**: Rich development environment with formatting, linting, validation
- **Home Manager**: Declarative user environment (packages, dotfiles, program configs)

## 📝 Key Things to Remember

### Your Git Setup

- **Personal repos** go in `~/Code/personal/` → uses `mail@ludovicvanasse.com`
- **Work repos** go in `~/Code/work/` → uses `lvanasse@luxaerobot.com`
- SSH keys are separate for each (see SSH setup guide)

### Configuration Structure

- **System stuff**: `modules/nixos/` (services, desktop, core system)
- **User stuff**: `modules/home/` (packages, program configs)
- **Machine-specific**: `hosts/pc/` and `hosts/laptop/`
- **Your user config**: `home/` directory

### Adding New Packages

Instead of one giant list, packages are organized by category:

- Development tools → `modules/home/packages/development.nix`
- Desktop apps → `modules/home/packages/desktop.nix`
- Gaming stuff → `modules/home/packages/gaming.nix`
- Creative tools → `modules/home/packages/creative.nix`

## 🔧 When You Need to...

### Add a New Package

1. Find the right category file in `modules/home/packages/`
1. Add the package to the list
1. Run `home-manager switch --flake .#ludovic@<host>`

### Change System Settings

1. Find the right module in `modules/nixos/`
1. Make your changes
1. Run `nh os switch -H <host>`

### Set Up a New Machine

1. Install NixOS
1. Clone this repo
1. Follow the SSH setup guide
1. Run the appropriate host configuration

That's it! Everything else is in the detailed docs if you need to dig deeper.
