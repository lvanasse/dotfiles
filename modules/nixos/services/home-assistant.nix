{ ... }:
{
  flake.modules.nixos."services.home-assistant" =
    { config, ... }:
    let
      appDataRoot = "/mnt/ssd/appdata/docker/home-assistant";
    in
    {
      assertions = [
        {
          assertion = config.virtualisation.docker.enable;
          message = "Home Assistant requires the server Docker service.";
        }
      ];

      virtualisation.oci-containers.containers.home-assistant = {
        image = "ghcr.io/home-assistant/home-assistant:2026.10.3@sha256:407b89cd11a8cb67d388d21739a226c74acbbebe1ac59e3b83b11b43ce76b98f";
        volumes = [ "${appDataRoot}:/config" ];
        environment.TZ = "America/Toronto";
        extraOptions = [
          "--network=host"
          "--stop-timeout=60"
        ];
      };

      systemd.services.docker-home-assistant = {
        requires = [ "mnt-ssd.mount" ];
        after = [ "mnt-ssd.mount" ];
        preStart = ''
          install -d -m 0700 ${appDataRoot}
          if [ ! -e ${appDataRoot}/configuration.yaml ]; then
            install -m 0644 ${./home-assistant/configuration.yaml} ${appDataRoot}/configuration.yaml
          fi
          if [ ! -e ${appDataRoot}/automations.yaml ]; then
            install -m 0644 ${./home-assistant/automations.yaml} ${appDataRoot}/automations.yaml
          fi
          if [ ! -e ${appDataRoot}/scripts.yaml ]; then
            printf '{}\n' > ${appDataRoot}/scripts.yaml
          fi
          if [ ! -e ${appDataRoot}/scenes.yaml ]; then
            printf '[]\n' > ${appDataRoot}/scenes.yaml
          fi
        '';
      };
    };
}
