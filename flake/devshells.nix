{ inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      devShells = {
        # Default development shell for working on the dotfiles
        default = pkgs.mkShell {
          name = "dotfiles-dev";
          packages = with pkgs; [
            # Nix tools
            nixfmt-rfc-style
            nil # Nix LSP
            nixpkgs-fmt
            nix-tree
            nix-diff
            nix-output-monitor
            nvd # Nix version diff

            # Development tools
            git
            gh # GitHub CLI
            just # Command runner
            treefmt # Formatting
            pre-commit # Git hooks

            # System tools
            nh # NixOS helper
            home-manager

            # Documentation
            mdbook

            # Validation tools
            statix # Nix linter
            deadnix # Dead code detection
          ];

          shellHook = ''
            echo "🚀 Welcome to the dotfiles development environment!"
            echo ""
            echo "Available commands:"
            echo "  nixfmt-rfc-style **/*.nix  - Format all Nix files"
            echo "  nh os switch -H <host>     - Switch NixOS configuration"
            echo "  home-manager switch --flake .#ludovic@<host> - Switch Home Manager"
            echo "  nix flake check            - Check flake validity"
            echo "  treefmt                    - Format all files"
            echo "  pre-commit install         - Install git hooks"
            echo ""
            echo "Hosts available: pc, laptop"
          '';
        };

        # Specialized shell for NixOS system work
        nixos = pkgs.mkShell {
          name = "nixos-dev";
          packages = with pkgs; [
            nixfmt-rfc-style
            nh
            nixos-rebuild
            nix-tree
            nix-diff
          ];
        };

        # Shell for Home Manager work
        home = pkgs.mkShell {
          name = "home-manager-dev";
          packages = with pkgs; [
            nixfmt-rfc-style
            home-manager
            nix-tree
          ];
        };
      };
    };
}
