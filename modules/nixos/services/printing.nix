{ ... }:
{
  flake.modules.nixos.servicesPrinting =
    { ... }:
    {
      # Printing services
      services.printing.enable = true;
    };
}
