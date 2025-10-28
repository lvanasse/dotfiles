# Codex CLI configuration (matches docs at developers.openai.com)
{ lib, config, ... }:
{
  # Persist CLI defaults per official reference:
  # - Config path: ~/.codex/config.toml
  # - Keys: model, model_reasoning_effort
  home.file.".codex/config.toml".text = ''
    model = "gpt-5"
    model_reasoning_effort = "high"
  '';

  # Convenience: quick alias to enable web search (flag per CLI reference)
  programs.fish = lib.mkIf config.programs.fish.enable {
    shellAbbrs = {
      cxw = "codex --search";
    };
  };
}
