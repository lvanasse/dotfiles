{ ... }:
{
  flake.modules.homeManager.programsClaude =
    { pkgs, ... }:
    let
      settingsFormat = pkgs.formats.json { };
      settings = {
        "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        permissions = {
          allow = [
            "Read"
            "WebFetch"
            "WebSearch"
            "Bash(git *)"
            "Bash(nix *)"
            "Bash(home-manager *)"
            "Bash(nh *)"
          ];
          deny = [
            "Read(.env)"
            "Read(.env.*)"
            "Read(**/secrets/**)"
          ];
        };
      };
    in
    {
      home.file.".claude/settings.json".source =
        settingsFormat.generate "claude-settings.json" settings;
    };
}
