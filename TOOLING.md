# Dotfiles Tooling

This document describes the development tooling available for managing this NixOS dotfiles configuration.

## Quick Start

```bash
# Enter development environment
nix develop

# Format all files
just fmt

# Validate all configurations
just validate

# Rebuild a host
just rebuild pc
```

## Available Tools

### Development Shells

- `nix develop` - Main development environment with all tools
- `nix develop .#nixos` - NixOS-focused development shell
- `nix develop .#home` - Home Manager-focused development shell

### Formatting

- `just fmt` - Format all files using treefmt
- `just check-fmt` - Check formatting without making changes
- `treefmt` - Direct treefmt usage

### Building and Testing

- `just build <host>` - Build a host configuration
- `just switch <host>` - Switch to a host configuration
- `just validate` - Validate all configurations build
- `just check` - Run all flake checks
- `nix flake check` - Direct flake validation

### Home Manager

- `just home <host>` - Switch Home Manager configuration
- `home-manager switch --flake .#ludovic@<host>` - Direct Home Manager usage

### Maintenance

- `just update` - Update flake inputs
- `just clean` - Clean up old generations
- `just diff <host>` - Show system differences after rebuild

### Git Hooks

- `just install-hooks` - Install pre-commit hooks
- `just pre-commit` - Run pre-commit hooks on all files

### Package Management

- `just search <query>` - Search for packages
- `just show <package>` - Show package information

## File Organization

```
dotfiles/
├── flake/              # Flake-parts modules
│   ├── devshells.nix   # Development environments
│   ├── checks.nix      # Configuration validation
│   ├── formatter.nix   # Code formatting setup
│   └── packages.nix    # Custom packages and overlays
├── lib/                # Custom library functions
├── hosts/              # Host-specific configurations
├── home/               # Home Manager configurations
├── modules/            # Shared modules (future)
├── justfile            # Command runner recipes
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
1. Run `just fmt` to format code
1. Run `just validate` to check configurations build
1. Test changes with `just build <host>`
1. Apply changes with `just switch <host>`
1. Commit changes (pre-commit hooks will run automatically)

## Troubleshooting

- If builds fail, check `nix flake check` output
- For formatting issues, run `just fmt`
- For syntax errors, use `nix-instantiate --parse <file>`
- Check the development shell with `nix develop`
