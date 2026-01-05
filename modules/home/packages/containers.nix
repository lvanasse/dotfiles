{ ... }:
{
  flake.modules.homeManager.packagesContainers =
    { pkgs, ... }:
    {
      # Containers / local tooling
      home.packages = with pkgs; [
        docker
      ];
    };
}
