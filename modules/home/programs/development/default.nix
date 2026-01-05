{ config, ... }:
{
  flake.modules.homeManager.development =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager.devGit
        config.flake.modules.homeManager.devEmacs
        config.flake.modules.homeManager.devDirenv
        config.flake.modules.homeManager.devJava
        config.flake.modules.homeManager.devVscode
      ];
    };
}
