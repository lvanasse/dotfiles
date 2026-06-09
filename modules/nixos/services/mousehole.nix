{ ... }:
{
  flake.modules.nixos."services.mousehole" =
    { ... }:
    let
      appDataRoot = "/mnt/data3/appdata/mousehole";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.mousehole = {
        image = "tmmrtn/mousehole:latest";
        environment = {
          TZ = "America/Toronto";
          MOUSEHOLE_PORT = "5010";
          MOUSEHOLE_STATE_DIR_PATH = "/srv/mousehole";
          # Mousehole v0.4.0 requires an explicit auth choice. This preserves
          # the previous unauthenticated behavior for the private server UI.
          MOUSEHOLE_INSECURE_ALLOW_NO_AUTH = "true";
        };
        volumes = [
          "${appDataRoot}:/srv/mousehole"
        ];
        ports = [ "5010:5010" ];
        extraOptions = [ "--label=com.centurylinklabs.watchtower.enable=true" ];
      };

      systemd.services.docker-mousehole = {
        requires = [
          "docker.service"
          "mnt-data3.mount"
        ];
        after = [
          "docker.service"
          "mnt-data3.mount"
        ];
      };

      networking.firewall.allowedTCPPorts = [ 5010 ];
    };
}
