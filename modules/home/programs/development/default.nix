{ config, ... }:
{
  flake.modules.homeManager."programs.development" =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager."programs.development.git"
        config.flake.modules.homeManager."programs.development.emacs"
        config.flake.modules.homeManager."programs.development.direnv"
        config.flake.modules.homeManager."programs.development.java"
        config.flake.modules.homeManager."programs.development.vscode"
      ];
    };
}
