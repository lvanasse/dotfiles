# Nix package manager configuration
{ config, pkgs, ... }:
{
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
  
  # Permitted insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "electron-33.4.11"
  ];

  # System state version
  system.stateVersion = "25.05";
}