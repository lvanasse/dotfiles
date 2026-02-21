{ ... }:
{
  flake.modules.nixos."server.docker" =
    { ... }:
    {
      virtualisation.docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      virtualisation.oci-containers.backend = "docker";
    };
}
