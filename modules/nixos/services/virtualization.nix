{ ... }:
{
  flake.modules.nixos."services.virtualization" =
    { ... }:
    {
      # Virtualization services
      # Docker
      virtualisation.docker.enable = true;
    };
}
