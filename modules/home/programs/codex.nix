{ ... }:
{
  flake.modules.homeManager.codex =
    { lib, config, pkgs, ... }:
    let
      defaultArgs = "--search -s danger-full-access -a on-request";
    in
    {
      # Codex CLI integration (no managed config.toml)
      home.packages = [
        pkgs.codex
      ];

      # Convenience: Codex defaults and shortcuts in fish
      programs.fish = lib.mkIf config.programs.fish.enable {
        functions = {
          codex = {
            description = "Codex CLI with search + full sandbox + on-request approvals by default";
            body = ''
              command codex ${defaultArgs} $argv
            '';
          };
        };
      };

      # Bash/Zsh aliases for non-Fish shells (useful on Ubuntu defaults)
      programs.bash = lib.mkIf config.programs.bash.enable {
        shellAliases = {
          codex = "codex ${defaultArgs}";
        };
      };
      programs.zsh = lib.mkIf config.programs.zsh.enable {
        shellAliases = {
          codex = "codex ${defaultArgs}";
        };
      };
    };
}
