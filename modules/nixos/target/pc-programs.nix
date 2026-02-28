{ ... }:
{
  flake.modules.nixos."targetConfig.pc.programs" =
    { ... }:
    {
      # Programs
      programs = {
        coolercontrol.enable = true;
      };
    };
}
