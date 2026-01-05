{ ... }:
{
  flake.modules.homeManager.codex =
    { lib, config, ... }:
    {
      # Codex CLI integration (no managed config.toml)
      # Convenience: Codex defaults and shortcuts in fish
      programs.fish = lib.mkIf config.programs.fish.enable {
        functions = {
          codex = {
            description = "Codex CLI with search + full sandbox + on-request approvals by default";
            body = ''
              command codex --search -s danger-full-access -a on-request $argv
            '';
          };
        };
      };
    };
}
