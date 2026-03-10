{ flakeModules, ... }:
{
  imports = [
    flakeModules.homeManager.core
    flakeModules.homeManager.terminal
    flakeModules.homeManager."programs.codex"
    flakeModules.homeManager."target.config.gateway"
  ];
}
