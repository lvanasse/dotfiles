{ ... }:
{
  flake.modules.homeManager."target.config.work-laptop" =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      homeDir = config.home.homeDirectory;
      personalKeyAge = "${inputs.secrets}/ssh/id_ed25519_personal.age";
      hasPersonalKeyAge = builtins.pathExists personalKeyAge;
    in
    {
      age.identityPaths = lib.mkAfter [ "${homeDir}/.ssh/agenix_work_laptop" ];

      age.secrets = lib.optionalAttrs hasPersonalKeyAge {
        "ssh-id-ed25519-personal" = {
          file = personalKeyAge;
          path = "${homeDir}/.ssh/id_ed25519_personal";
          mode = "0600";
        };
      };
    };
}
