{
  description = "lvanasse's NixOS dotfiles with improved organization and tooling";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Flake organization
    flake-parts.url = "github:hercules-ci/flake-parts";

    # System management
    determinate.url = "github:DeterminateSystems/determinate";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop environment
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Applications
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Theming
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development tools
    nix-gc-env.url = "github:Julow/nix-gc-env";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional package sources
    "nixpkgs-unstable".url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Tooling
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Supported systems
      systems = [ "x86_64-linux" ];

      # Import flake-parts modules
      imports = [
        ./flake/checks.nix
        ./flake/formatter.nix
        ./flake/packages.nix
      ];

      # Flake-level outputs
      flake =
        let
          # Custom qBittorrent overlay
          qbittorrent510 = _final: prev: {
            qbittorrent = prev.qbittorrent.overrideAttrs (_: {
              version = "5.1.0";
              src = prev.fetchurl {
                url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.1.0.tar.gz";
                sha256 = "sha256-rFTNizxgNc/NaEvlr9DszIxfu8MAiptvm6QvbvkRBa8=";
              };
            });
          };

          # Helper function to create a host configuration
          mkHost =
            {
              hostname,
              username ? "ludovic",
              system ? "x86_64-linux",
              overlays ? [ ],
              extraModules ? [ ],
            }:
            inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = {
                inherit
                  inputs
                  username
                  hostname
                  ;
              };
              modules = [
                (
                  { ... }:
                  {
                    nixpkgs.overlays = overlays;
                  }
                )
                ./hosts/${hostname}/${hostname}.nix
                inputs.determinate.nixosModules.default
                inputs.home-manager.nixosModules.home-manager
                inputs.nix-flatpak.nixosModules.nix-flatpak
                inputs.nix-gc-env.nixosModules.default
                (
                  { ... }:
                  {
                    home-manager.useUserPackages = true;
                    home-manager.users.${username} = {
                      nixpkgs.overlays = overlays ++ [ inputs.nix-vscode-extensions.overlays.default ];
                      nixpkgs.config.allowUnfree = true;
                      imports = [
                        ./modules/home
                      ];
                    };
                    home-manager.extraSpecialArgs = {
                      inherit inputs username hostname;
                    };
                    home-manager.sharedModules = [
                      inputs.plasma-manager.homeModules.plasma-manager
                      inputs.stylix.homeModules.stylix
                    ];
                  }
                )
              ]
              ++ extraModules;
            };
        in
        {
          # NixOS configurations
          nixosConfigurations = {
            pc = mkHost {
              hostname = "pc";
              overlays = [
                qbittorrent510
                inputs.nix-vscode-extensions.overlays.default
              ];
            };

            laptop = mkHost {
              hostname = "laptop";
              overlays = [ inputs.nix-vscode-extensions.overlays.default ];
            };
          };

          # Home Manager configurations (standalone)
          homeConfigurations =
            let
              mkHome =
                hostname:
                inputs.home-manager.lib.homeManagerConfiguration {
                  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
                  modules = [
                    {
                      nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
                      nixpkgs.config.allowUnfree = true;
                    }
                    ./modules/home
                    inputs.plasma-manager.homeModules.plasma-manager
                    inputs.stylix.homeModules.stylix
                  ];
                  extraSpecialArgs = {
                    inherit inputs;
                    hostname = hostname;
                    username = "ludovic";
                  };
                };
            in
            {
              "ludovic@pc" = mkHome "pc";
              "ludovic@laptop" = mkHome "laptop";
            };
        };
    };
}
