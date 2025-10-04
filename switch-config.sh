#!/usr/bin/env bash

# Script to switch between old and new configuration structures

set -e

FLAKE_FILE="flake.nix"

show_usage() {
    echo "Usage: $0 [new|old]"
    echo ""
    echo "  new  - Switch to new modular configuration"
    echo "  old  - Switch to original configuration"
    echo ""
    echo "Current configuration:"
    if grep -q "pc-new.nix" "$FLAKE_FILE"; then
        echo "  ✅ Using NEW modular configuration"
    else
        echo "  📁 Using ORIGINAL configuration"
    fi
}

switch_to_new() {
    echo "🔄 Switching to NEW modular configuration..."
    
    # Update host configurations
    sed -i 's|hosts/${hostname}/${hostname}\.nix|hosts/${hostname}/${hostname}-new.nix|g' "$FLAKE_FILE"
    
    # Update home configuration
    sed -i 's|home/default\.nix|home/default-new.nix|g' "$FLAKE_FILE"
    
    echo "✅ Switched to NEW modular configuration"
    echo ""
    echo "To apply changes:"
    echo "  nix flake check                    # Validate configuration"
    echo "  nh os switch -H pc                # Switch PC (if applicable)"
    echo "  nh os switch -H laptop            # Switch laptop (if applicable)"
}

switch_to_old() {
    echo "🔄 Switching to ORIGINAL configuration..."
    
    # Update host configurations
    sed -i 's|hosts/${hostname}/${hostname}-new\.nix|hosts/${hostname}/${hostname}.nix|g' "$FLAKE_FILE"
    
    # Update home configuration
    sed -i 's|home/default-new\.nix|home/default.nix|g' "$FLAKE_FILE"
    
    echo "✅ Switched to ORIGINAL configuration"
    echo ""
    echo "To apply changes:"
    echo "  nix flake check                    # Validate configuration"
    echo "  nh os switch -H pc                # Switch PC (if applicable)"
    echo "  nh os switch -H laptop            # Switch laptop (if applicable)"
}

case "${1:-}" in
    "new")
        switch_to_new
        ;;
    "old")
        switch_to_old
        ;;
    *)
        show_usage
        exit 1
        ;;
esac