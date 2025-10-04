# Justfile for dotfiles management
# Run `just` to see available commands

# Default recipe - show help
default:
    @just --list

# Format all files
fmt:
    treefmt

# Check formatting without making changes
check-fmt:
    treefmt --fail-on-change

# Run all checks
check:
    nix flake check

# Build a specific host configuration
build HOST:
    nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel

# Switch to a host configuration
switch HOST:
    nh os switch -H {{HOST}}

# Switch Home Manager configuration
home HOST:
    home-manager switch --flake .#ludovic@{{HOST}}

# Update flake inputs
update:
    nix flake update

# Show flake info
info:
    nix flake show

# Clean up old generations
clean:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

# Install pre-commit hooks
install-hooks:
    pre-commit install

# Run pre-commit hooks on all files
pre-commit:
    pre-commit run --all-files

# Show system diff after rebuild
diff HOST:
    nvd diff /run/current-system result

# Enter development shell
dev:
    nix develop

# Validate all configurations build
validate:
    @echo "🔍 Validating PC configuration..."
    nix build .#nixosConfigurations.pc.config.system.build.toplevel --no-link
    @echo "🔍 Validating laptop configuration..."
    nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
    @echo "🔍 Validating Home Manager configurations..."
    nix build .#homeConfigurations.\"ludovic@pc\".activationPackage --no-link
    nix build .#homeConfigurations.\"ludovic@laptop\".activationPackage --no-link
    @echo "✅ All configurations are valid!"

# Show what would be rebuilt
dry-run HOST:
    nixos-rebuild dry-run --flake .#{{HOST}}

# Search for packages
search QUERY:
    nix search nixpkgs {{QUERY}}

# Show package info
show PACKAGE:
    nix eval nixpkgs#{{PACKAGE}}.meta.description

# Rebuild and show diff
rebuild HOST:
    just build {{HOST}}
    just switch {{HOST}}
    just diff {{HOST}}