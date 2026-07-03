{
  inputs,
  config,
  lib,
  ...
}:
let
  nixpkgsConfig = {
    allowUnfree = true;
    permittedInsecurePackages = [
      # Required by bitwarden-desktop 2026.5.0 on NixOS 26.05.
      "electron-39.8.10"
    ];
  };

  overlays = [
    config.flake.overlays.unstablePackages
    config.flake.overlays.qbittorrent510_2505
    config.flake.overlays.agenixFromInput
    inputs.nix-vscode-extensions.overlays.default
    inputs.emacs-overlay.overlays.default
    inputs.llm-agents.overlays.default
    config.flake.overlays.sonarlintHashFix
    inputs.nixgl.overlay
  ];

  getModules =
    modules: names:
    lib.concatMap (name: if lib.hasAttr name modules then [ modules.${name} ] else [ ]) names;

  mkNixosConfiguration =
    {
      hostname,
      system,
      username,
      modules,
      extraModules ? [ ],
      nixpkgsInput ? inputs.nixpkgs,
      homeManagerInput ? inputs.home-manager,
      sharedHomeModules ? [ inputs.plasma-manager.homeModules.plasma-manager ],
    }:
    let
      nixosModules = getModules config.flake.modules.nixos modules;
      hmModules = getModules config.flake.modules.homeManager modules;
    in
    nixpkgsInput.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs username;
        flakeModules = config.flake.modules;
      };
      modules = [
        (
          { ... }:
          {
            networking.hostName = hostname;
            nixpkgs = {
              inherit overlays;
              config = nixpkgsConfig;
            };
          }
        )
        inputs.determinate.nixosModules.default
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.nix-gc-env.nixosModules.default
        inputs.agenix.nixosModules.default
        homeManagerInput.nixosModules.home-manager
        (
          { ... }:
          {
            home-manager = {
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              overwriteBackup = true;
              extraSpecialArgs = {
                inherit inputs username;
                flakeModules = config.flake.modules;
              };
              users.${username} = {
                imports = hmModules;
                nixpkgs = {
                  inherit overlays;
                  config = nixpkgsConfig;
                };
              };
              sharedModules = sharedHomeModules;
            };
          }
        )
      ]
      ++ nixosModules
      ++ extraModules;
    };

  mkHomeConfiguration =
    {
      system,
      modules,
      extraModules ? [ ],
      username ? config.flake.lib.username,
      nixpkgsInput ? inputs.nixpkgs,
      homeManagerInput ? inputs.home-manager,
      sharedHomeModules ? [ inputs.plasma-manager.homeModules.plasma-manager ],
      ...
    }:
    let
      hmModules = getModules config.flake.modules.homeManager modules;
    in
    homeManagerInput.lib.homeManagerConfiguration {
      pkgs = import nixpkgsInput {
        inherit system overlays;
        config = nixpkgsConfig;
      };
      extraSpecialArgs = {
        inherit inputs username;
        flakeModules = config.flake.modules;
      };
      modules = [
        inputs.agenix.homeManagerModules.default
      ]
      ++ hmModules
      ++ sharedHomeModules
      ++ extraModules;
    };

in
{
  flake.lib = {
    username = "ludovic";
    inherit
      overlays
      getModules
      mkNixosConfiguration
      mkHomeConfiguration
      ;
  };
}
