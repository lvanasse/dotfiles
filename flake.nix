{
  description = "lvanasse's NixOS dotfiles with improved organization and tooling";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

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
    "nixpkgs-2505".url = "github:NixOS/nixpkgs/nixos-25.05";

    # Tooling
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Emacs overlay for up-to-date Emacs and MELPA packages
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Editor: Spacemacs pinned via flake input for reproducibility
    spacemacs = {
      url = "github:syl20bnr/spacemacs?ref=develop";
      flake = false;
    };

    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Private secrets repository (non-flake)
    secrets = {
      url = "git+ssh://git@codeberg.org/lvanasse/secrets.git?ref=main";
      flake = false;
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
          # Pull codex from nixpkgs-unstable so it tracks its latest available build
          codexFromUnstable =
            final: prev:
            let
              system = prev.stdenv.hostPlatform.system;
              unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
            in
            {
              codex = unstable.codex;
            };

          qbittorrent510_2505 =
            _final: prev:
            {
              qbittorrent = prev.qbittorrent.overrideAttrs (_: {
                version = "5.1.0";
                src = prev.fetchurl {
                  url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.1.0.tar.gz";
                  sha256 = "sha256-rFTNizxgNc/NaEvlr9DszIxfu8MAiptvm6QvbvkRBa8=";
                };
              });
            };

          # Fix broken upstream hash for sonarlint-ls fetched Maven deps
          sonarlintHashFix =
            final: prev:
            {
              sonarlint-ls = prev.callPackage ./overrides/sonarlint-ls/package.nix { };
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
                (_: {
                  nixpkgs.overlays = overlays;
                })
                ./hosts/${hostname}/${hostname}.nix
                inputs.agenix.nixosModules.default
                inputs.determinate.nixosModules.default
                inputs.home-manager.nixosModules.home-manager
                inputs.nix-flatpak.nixosModules.nix-flatpak
                inputs.nix-gc-env.nixosModules.default
                (_: {
                  home-manager = {
                    useUserPackages = true;
                    backupFileExtension = "hm-bak";
                    users.${username} = {
                      nixpkgs.overlays =
                        overlays
                        ++ [
                          inputs.nix-vscode-extensions.overlays.default
                          inputs.emacs-overlay.overlays.default
                        ]
                        ++ [ sonarlintHashFix ];
                      nixpkgs.config.allowUnfree = true;
                      imports = [
                        ./modules/home
                      ];
                    };
                    extraSpecialArgs = {
                      inherit inputs username hostname;
                    };
                    sharedModules = [
                      inputs.plasma-manager.homeModules.plasma-manager
                      inputs.stylix.homeModules.stylix
                    ];
                  };
                })
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
                qbittorrent510_2505
                codexFromUnstable
                inputs.nix-vscode-extensions.overlays.default
                inputs.emacs-overlay.overlays.default
                sonarlintHashFix
              ];
            };

            laptop = mkHost {
              hostname = "laptop";
              overlays = [
                qbittorrent510_2505
                codexFromUnstable
                inputs.nix-vscode-extensions.overlays.default
                inputs.emacs-overlay.overlays.default
                sonarlintHashFix
              ];
            };
          };

          # Home Manager configurations (standalone)
          homeConfigurations =
            let
              mkHome =
                hostname:
                inputs.home-manager.lib.homeManagerConfiguration {
                  pkgs = import inputs.nixpkgs {
                    system = "x86_64-linux";
                    overlays = [
                      qbittorrent510_2505
                      codexFromUnstable
                      inputs.nix-vscode-extensions.overlays.default
                      inputs.emacs-overlay.overlays.default
                      sonarlintHashFix
                    ];
                    config.allowUnfree = true;
                  };
                  modules = [
                    ./modules/home
                    inputs.plasma-manager.homeModules.plasma-manager
                    inputs.stylix.homeModules.stylix
                    # inputs.agenix.homeManagerModules.default  # Uncomment if you want HM-managed secrets
                  ];
                  extraSpecialArgs = {
                    inherit inputs hostname;
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
