{ inputs, lib, ... }:
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
      };

      # Automatic garbage collection
      nix.gc = {
        automatic = true;
        dates = "weekly";
        delete_generations = "+5";
      };

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

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
