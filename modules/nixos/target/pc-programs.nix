{ ... }:
{
  flake.modules.nixos."target.config.pc.programs" =
    { ... }:
    {
      # Programs
      programs = {
        coolercontrol.enable = true;
      };
    };
}
