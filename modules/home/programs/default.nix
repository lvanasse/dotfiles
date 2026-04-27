{ config, ... }:
{
  flake.modules.homeManager.programs =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager.terminal
        config.flake.modules.homeManager."programs.nix"
        config.flake.modules.homeManager."programs.ssh"
        config.flake.modules.homeManager."programs.aider"
        config.flake.modules.homeManager."programs.development"
        config.flake.modules.homeManager."programs.slack"
        config.flake.modules.homeManager."programs.vesktop"
        config.flake.modules.homeManager."programs.codex"
        config.flake.modules.homeManager."programs.rtk"
        config.flake.modules.homeManager."programs.jira"
        config.flake.modules.homeManager."programs.firefox"
        config.flake.modules.homeManager."programs.email"
        config.flake.modules.homeManager."programs.calendar"
      ];
    };
}
