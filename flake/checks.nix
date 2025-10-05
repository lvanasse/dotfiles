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
      checks = {
        # Check that all configurations build successfully
        nixos-pc = inputs.self.nixosConfigurations.pc.config.system.build.toplevel;
        nixos-laptop = inputs.self.nixosConfigurations.laptop.config.system.build.toplevel;

        # Check Home Manager configurations build
        # Note: These are checked as part of the NixOS configurations

        # Formatting check
        formatting = pkgs.runCommand "check-formatting" { } ''
          ${pkgs.nixfmt-rfc-style}/bin/nixfmt --check ${inputs.self}/**/*.nix
          touch $out
        '';

        # Nix file syntax check
        nix-syntax = pkgs.runCommand "check-nix-syntax" { } ''
          find ${inputs.self} -name "*.nix" -exec ${pkgs.nix}/bin/nix-instantiate --parse {} \; > /dev/null
          touch $out
        '';

        # Dead code detection
        deadnix-check = pkgs.runCommand "deadnix-check" { } ''
          ${pkgs.deadnix}/bin/deadnix --fail ${inputs.self}
          touch $out
        '';

        # Statix linting
        statix-check = pkgs.runCommand "statix-check" { } ''
          ${pkgs.statix}/bin/statix check ${inputs.self}
          touch $out
        '';

        # Pre-commit hooks
        pre-commit = inputs.pre-commit-hooks.lib.${system}.run {
          src = inputs.self;
          hooks = {
            nixfmt-rfc-style.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            markdownlint.enable = true;
          };
        };
      };
    };
}
