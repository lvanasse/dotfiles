{
  config,
  inputs,
  lib,
  ...
}:
let
  username = config.flake.lib.username;

  personalPub = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  personalKeyAge = "${inputs.secrets}/ssh/id_ed25519_personal.age";

  hasPersonalPub = builtins.pathExists personalPub;
  hasPersonalKeyAge = builtins.pathExists personalKeyAge;
in
{
  flake.modules.nixos."services.ssh-keys" =
    { config, ... }:
    let
      receivesClientKey = lib.elem config.networking.hostName [
        "pc"
        "laptop"
      ];
    in
    {
      # gnome-keyring already starts gcr-ssh-agent; disable the legacy ssh-agent to avoid conflicts.
      programs.ssh.startAgent = lib.mkForce false;

      # Passwordless auth uses the shared personal admin key on every target.
      users.users.${username}.openssh.authorizedKeys.keys = lib.optionals hasPersonalPub [
        (builtins.readFile personalPub)
      ];

      systemd.tmpfiles.rules = lib.optionals receivesClientKey [
        "d /home/${username}/.ssh 0700 ${username} users -"
      ];

      age.secrets = lib.optionalAttrs (receivesClientKey && hasPersonalKeyAge) {
        "ssh-id-ed25519-personal" = {
          file = personalKeyAge;
          path = "/home/${username}/.ssh/id_ed25519_personal";
          mode = "0600";
          owner = username;
          group = "users";
        };
      };
    };
}
