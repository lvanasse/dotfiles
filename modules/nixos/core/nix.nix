{ inputs, lib, ... }:
let
  atticCachePublicKeyFile = "${inputs.secrets}/server/attic-cache-public-key";
  hasAtticCachePublicKey = builtins.pathExists atticCachePublicKeyFile;
  atticCachePublicKey = lib.strings.removeSuffix "\n" (builtins.readFile atticCachePublicKeyFile);
in
{
  flake.modules.nixos."core.nix" =
    { pkgs, ... }:
    {
      # Nix package manager configuration

      # Follow the default kernel track from the unstable nixpkgs input.
      boot.kernelPackages = pkgs.unstable.linuxPackages;

      # Nix settings and experimental features
      nix.settings = {
        # DetSys Nix settings
        lazy-trees = true;
        eval-cores = 0; # parallel eval
        auto-optimise-store = true;

        experimental-features = [
          "nix-command"
          "flakes"
          "parallel-eval"
        ];

        trusted-users = [
          "root"
          "ludovic"
        ];
      }
      // lib.optionalAttrs hasAtticCachePublicKey {
        extra-substituters = [ "http://server.tail7e8d6c.ts.net:8080/dotfiles" ];
        extra-trusted-public-keys = [ atticCachePublicKey ];
      };

      system.activationScripts.agenixRuntimePathCleanup.text = ''
        if [ -d /run/agenix ] && [ ! -L /run/agenix ]; then
          rm -rf /run/agenix
        fi
      '';
      system.activationScripts.agenixInstall.deps = lib.mkAfter [ "agenixRuntimePathCleanup" ];

      # Automatic garbage collection
      nix.gc = {
        automatic = true;
        dates = "weekly";
        delete_generations = "+5";
      };

      nixpkgs.config = {
        allowUnfree = true;
        # Bitwarden Desktop still requires the EOL Electron 39 release.
        permittedInsecurePackages = [ "electron-39.8.10" ];
      };

      # Use this flake as the nixpkgs registry source (wrapper enables unfree)
      nix.registry.nixpkgs = lib.mkForce {
        flake = inputs.self;
      };

      # Disk space visibility tools available on all NixOS targets.
      environment.systemPackages = with pkgs; [
        duf
        dust
        ncdu
      ];

      # System state version
      system.stateVersion = "25.05";
    };
}
