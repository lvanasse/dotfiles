{ inputs, ... }:
{
  flake.modules.homeManager."programs.codex" =
    { lib, config, pkgs, ... }:
    let
      defaultArgs = "--search -s danger-full-access -a on-request";
      codexPkg = pkgs.llm-agents.codex;
      codexWrapped = pkgs.writeShellScriptBin "codex" ''
        exec ${lib.getExe codexPkg} ${defaultArgs} "$@"
      '';
    in
    {
      # Codex CLI integration (no managed config.toml)
      home.packages = [
        codexWrapped
      ];

      # Convenience: Codex defaults and shortcuts in fish
      programs.fish = lib.mkIf config.programs.fish.enable {
        functions = {
          codex = {
            description = "Codex CLI with search + full sandbox + on-request approvals by default";
            body = ''
              command codex $argv
            '';
          };
        };
      };
    };
}
