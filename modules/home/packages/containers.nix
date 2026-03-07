{ ... }:
{
  flake.modules.homeManager."packages.containers" =
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
