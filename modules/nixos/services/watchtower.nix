{ ... }:
{
  flake.modules.nixos."services.watchtower" =
    { ... }:
    {
      virtualisation.oci-containers.containers.watchtower = {
        image = "containrrr/watchtower:latest";
        environment = {
          WATCHTOWER_SCHEDULE = "0 0 4 * * *";
          WATCHTOWER_CLEANUP = "true";
          WATCHTOWER_LABEL_ENABLE = "true";
        };
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      };
    };
}
