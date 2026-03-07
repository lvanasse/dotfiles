{ ... }:
{
  flake.modules.homeManager."programs.development.java" =
    { pkgs, ... }:
    {
      programs.java = {
        enable = true;
        package = pkgs.openjdk21;
      };
    };
}
