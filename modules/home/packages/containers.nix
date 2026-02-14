{ ... }:
{
  flake.modules.homeManager.packagesContainers =
    { pkgs, ... }:
    {
      # Containers / local tooling
      home.packages = with pkgs; [
        docker
        containerd
        docker-compose
        docker-buildx
      ];
    };
}
