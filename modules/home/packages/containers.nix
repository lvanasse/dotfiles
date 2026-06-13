{ ... }:
{
  flake.modules.homeManager."packages.containers" =
    { pkgs, ... }:
    {
      # Containers / local tooling
      home.packages = with pkgs; [
        docker_29
        containerd
        docker-compose
        docker-buildx
      ];
    };
}
