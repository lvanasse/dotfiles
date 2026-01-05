{ ... }:
{
  flake.modules.homeManager.devDirenv =
    { ... }:
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
}
