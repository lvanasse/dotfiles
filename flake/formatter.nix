{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      # Treefmt configuration for consistent formatting
      treefmt.config = {
        projectRootFile = "flake.nix";

        programs = {
          # Nix formatting
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
          };

          # Markdown formatting
          mdformat.enable = true;

          # YAML formatting
          yamlfmt.enable = true;

          # Shell script formatting
          shfmt.enable = true;

          # JSON formatting
          prettier = {
            enable = true;
            includes = [ "*.json" ];
          };
        };

        settings.global.excludes = [
          "*.lock"
          "*.age"
          "result*"
          ".git/**"
          "tmp/**"
          # Ignore removed zsh config lingering in HEAD until next commit
          "modules/home/programs/terminal/zsh.nix"
        ];
      };

      # Make treefmt available as the default formatter
      formatter = config.treefmt.build.wrapper;
    };
}
