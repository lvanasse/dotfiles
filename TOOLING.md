# Dotfiles Tooling

This document describes the development tooling available for managing this NixOS dotfiles configuration.

## Quick Start

```bash
# Enter development environment
nix develop

# Format all files
nix fmt

# Validate all configurations
nix flake check

# Rebuild a host
nh os switch -H pc
```

## Available Tools

### Development Shells

- `nix develop` - Main development environment with all tools
- `nix develop .#nixos` - NixOS-focused development shell
- `nix develop .#home` - Home Manager-focused development shell

### Formatting

- `nix fmt` - Format all files using treefmt
- `treefmt --fail-on-change` - Check formatting without making changes
- `treefmt` - Direct treefmt usage

### Building and Testing

- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` - Build a host configuration
- `nh os switch -H <host>` - Switch to a host configuration
- `nix flake check` - Validate all configurations and run checks

### Home Manager

- `home-manager switch --flake .#ludovic@<host>` - Switch Home Manager configuration

### Maintenance

- `nix flake update` - Update flake inputs
- `nix-collect-garbage -d` - Clean up old generations
- `nvd diff /run/current-system result` - Show system differences after rebuild

### Git Hooks

- `pre-commit install` - Install pre-commit hooks
- `pre-commit run --all-files` - Run pre-commit hooks on all files

### Package Management

- `nix search nixpkgs <query>` - Search for packages
- `nix eval nixpkgs#<package>.meta.description` - Show package information

## File Organization

```
dotfiles/
├── flake/              # Flake-parts modules
│   ├── devshells.nix   # Development environments
│   ├── checks.nix      # Configuration validation
│   ├── formatter.nix   # Code formatting setup
│   └── packages.nix    # Custom packages and overlays
├── lib/                # Custom library functions
├── treefmt.toml        # Formatting configuration
└── .pre-commit-config.yaml # Git hooks configuration
```

## Checks and Validation

The configuration includes several automated checks:

- **Build validation**: Ensures all configurations build successfully
- **Formatting**: Checks code formatting with nixfmt-rfc-style
- **Syntax**: Validates Nix syntax
- **Dead code**: Detects unused code with deadnix
- **Linting**: Static analysis with statix
- **Pre-commit hooks**: Automated checks on git commits

## Development Workflow

1. Make changes to configuration files
2. Run `nix fmt` to format code
3. Run `nix flake check` to check configurations build
4. Test changes with `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
5. Apply changes with `nh os switch -H <host>`
6. Commit changes (pre-commit hooks will run automatically)

## Troubleshooting

- If builds fail, check `nix flake check` output
- For formatting issues, run `nix fmt`
- For syntax errors, use `nix-instantiate --parse <file>`
- Check the development shell with `nix develop`
