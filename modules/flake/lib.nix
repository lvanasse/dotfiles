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
    inputs.nix-openclaw.overlays.default
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
    }:
    let
      nixosModules = getModules config.flake.modules.nixos modules;
      hmModules = getModules config.flake.modules.homeManager modules;
    in
    inputs.nixpkgs.lib.nixosSystem {
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
        inputs.home-manager.nixosModules.home-manager
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
              sharedModules = [
                inputs.plasma-manager.homeModules.plasma-manager
              ];
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
      ...
    }:
    let
      hmModules = getModules config.flake.modules.homeManager modules;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
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
      ++ [
        inputs.plasma-manager.homeModules.plasma-manager
      ]
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
