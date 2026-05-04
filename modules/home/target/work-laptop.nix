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
    in
    {
      age.identityPaths = lib.mkForce [];
      age.secrets = lib.mkForce { };

      # Keep user-level Nix cache settings present on the HM-only work laptop.
      # The host still needs to trust this user before restricted settings apply.
      home.file.".config/nix/nix.conf".text = ''
        experimental-features = nix-command flakes
        substituters = https://cache.nixos.org/ https://cache.numtide.com
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
      '';

      # Keep the locally provisioned personal public key on the work laptop.
      home.file.".ssh/id_ed25519_personal.pub".enable = lib.mkForce false;
    };
}
