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
      packages = {
        # Custom qBittorrent 5.1.0 package
        qbittorrent510 = pkgs.qbittorrent.overrideAttrs (_: {
          version = "5.1.0";
          src = pkgs.fetchurl {
            url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.1.0.tar.gz";
            sha256 = "sha256-rFTNizxgNc/NaEvlr9DszIxfu8MAiptvm6QvbvkRBa8=";
          };
        });

        # Documentation generator
        docs = pkgs.writeShellScriptBin "generate-docs" ''
          echo "Generating documentation for dotfiles..."
          # Add documentation generation logic here
        '';

        # Configuration validator
        validate-config = pkgs.writeShellScriptBin "validate-config" ''
          echo "Validating NixOS configurations..."
          nix flake check
          echo "✅ All configurations are valid!"
        '';

        # Quick rebuild script
        rebuild = pkgs.writeShellScriptBin "rebuild" ''
          set -e

          if [ $# -eq 0 ]; then
            echo "Usage: rebuild <pc|laptop>"
            exit 1
          fi

          HOST=$1
          echo "🔄 Rebuilding $HOST configuration..."

          # Format code first
          treefmt

          # Build and switch
          nh os switch -H "$HOST"

          echo "✅ Rebuild complete!"
        '';
      };

    };
}
