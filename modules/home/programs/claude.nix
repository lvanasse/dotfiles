# Claude Code CLI integration
{ lib, config, ... }:
{
  # Convenience: Claude Code with default permissions
  programs.fish = lib.mkIf config.programs.fish.enable {
    functions = {
      claude = {
        description = "Claude Code with permission prompts";
        body = ''
          command claude $argv
        '';
      };
    };
  };
}
