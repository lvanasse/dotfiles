{
  inputs,
  config,
  lib,
  ...
}:
let
  overlays = [
    config.flake.overlays.codexFromUnstable
    config.flake.overlays.qbittorrent510_2505
    inputs.nix-vscode-extensions.overlays.default
    inputs.emacs-overlay.overlays.default
    config.flake.overlays.sonarlintHashFix
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
      };
      modules = [
        (
          { ... }:
          {
            networking.hostName = hostname;
            nixpkgs = {
              inherit overlays;
              config.allowUnfree = true;
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
              users.${username} = {
                imports = hmModules;
                nixpkgs = {
                  inherit overlays;
                  config.allowUnfree = true;
                };
              };
              sharedModules = [
                inputs.plasma-manager.homeModules.plasma-manager
                inputs.stylix.homeModules.stylix
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
      ...
    }:
    let
      hmModules = getModules config.flake.modules.homeManager modules;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      modules =
        hmModules
        ++ [
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.stylix.homeModules.stylix
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
