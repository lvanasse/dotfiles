{ ... }:
{
  flake.modules.nixos."services.printing" =
    { ... }:
    {
      # Printing services
      services.printing.enable = true;
    };
}
