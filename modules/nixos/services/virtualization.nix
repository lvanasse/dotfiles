{ ... }:
{
  flake.modules.nixos."services.virtualization" =
    { pkgs, ... }:
    {
      # Virtualization services
      # Docker
      virtualisation.docker = {
        enable = true;
        package = pkgs.docker_29;
      };
    };
}
