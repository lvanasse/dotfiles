{
  description = "lvanasse's NixOS dotfiles with improved organization and tooling";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-weekly.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";

    # Flake organization
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # System management
    determinate.url = "github:DeterminateSystems/determinate";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop environment
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disk provisioning
    disko.url = "github:nix-community/disko";

    # Applications
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Theming
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development tools
    nix-gc-env.url = "github:Julow/nix-gc-env";
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw.url = "github:openclaw/nix-openclaw";
    llm-agents.url = "github:numtide/llm-agents.nix";

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

    # nixGL for OpenGL/Vulkan on non-NixOS
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs."import-tree" ./modules)
        ./targets/default.nix
      ];
    };
}
