{ ... }:
{
  flake.modules.nixos.servicesVirtualization =
    { ... }:
    {
      # Virtualization services
      # Docker
      virtualisation.docker.enable = true;
    };
}
