{ ... }:
{
  flake.modules.homeManager.devJava =
    { pkgs, ... }:
    {
      programs.java = {
        enable = true;
        package = pkgs.openjdk21;
      };
    };
}
