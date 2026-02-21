{ config, ... }:
{
  flake.modules.homeManager.programs =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager.terminal
        config.flake.modules.homeManager.programsNix
        config.flake.modules.homeManager.programsSsh
        config.flake.modules.homeManager.development
        config.flake.modules.homeManager.slack
        config.flake.modules.homeManager.codex
        config.flake.modules.homeManager.jira
        config.flake.modules.homeManager.firefox
        config.flake.modules.homeManager.email
        config.flake.modules.homeManager.calendar
      ];
    };
}
