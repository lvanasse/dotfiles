# Personal NixOS Dotfiles

My personal NixOS configuration using flakes, supporting both my desktop PC and laptop.

## Quick Start

```bash
# Switch system configuration
nh os switch -H pc        # Desktop
nh os switch -H laptop    # Laptop

# Apply user environment
home-manager switch --flake .#ludovic@pc
home-manager switch --flake .#ludovic@laptop

# Development
nix develop               # Enter dev environment
nix fmt                   # Format code
nix flake check          # Validate everything
```

## Documentation

All documentation is in the [`docs/`](docs/) directory:

- **[Quick Reference](docs/README.md)** - Start here for daily commands and overview
- **[Repository Overview](docs/architecture/repository-overview.md)** - Complete structure guide
- **[Tooling Guide](docs/development/tooling.md)** - Development tools and workflow
- **[SSH Setup](docs/guides/setup-ssh-keys.md)** - Git SSH configuration for work/personal

## Key Features

- **Modular Configuration**: Clean, organized modules instead of monolithic files
- **Multi-Host Support**: Separate configs for PC and laptop
- **Work/Personal Git**: Automatic account switching based on directory
- **Development Tooling**: Rich dev environment with formatting, linting, validation
- **Home Manager**: Declarative user environment management
