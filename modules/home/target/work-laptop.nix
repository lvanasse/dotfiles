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
      age.identityPaths = lib.mkForce [
        "${homeDir}/.ssh/id_ed25519_personal"
        "${homeDir}/.ssh/id_ed25519_work"
      ];
      age.secrets = lib.optionalAttrs hasPersonalKeyAge {
        "ssh-id-ed25519-personal" = {
          file = personalKeyAge;
          path = "${homeDir}/.ssh/id_ed25519_personal";
          mode = "0600";
        };
      };

      # Keep user-level Nix cache settings present on the HM-only work laptop.
      # The host still needs to trust this user before restricted settings apply.
      home.file.".config/nix/nix.conf".text = ''
        experimental-features = nix-command flakes
        substituters = https://cache.nixos.org/ https://cache.numtide.com
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
      '';

      # Keep the existing local public key file to avoid clobbering the bootstrap key path.
      home.file.".ssh/id_ed25519_personal.pub".enable = lib.mkForce false;
    };
}
