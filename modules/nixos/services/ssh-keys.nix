{
  config,
  inputs,
  lib,
  ...
}:
let
  username = config.flake.lib.username;

  personalPub = "${inputs.secrets}/keys/id_ed25519_personal.pub";
  workPub = "${inputs.secrets}/keys/id_ed25519_work.pub";
  personalKeyAge = "${inputs.secrets}/ssh/id_ed25519_personal.age";
  workKeyAge = "${inputs.secrets}/ssh/id_ed25519_work.age";

  hasPersonalPub = builtins.pathExists personalPub;
  hasWorkPub = builtins.pathExists workPub;
  hasPersonalKeyAge = builtins.pathExists personalKeyAge;
  hasWorkKeyAge = builtins.pathExists workKeyAge;
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
      users.users.${username}.openssh.authorizedKeys.keys =
        lib.optionals hasPersonalPub [ (builtins.readFile personalPub) ]
        ++ lib.optionals hasWorkPub [ (builtins.readFile workPub) ];

      systemd.tmpfiles.rules = lib.optionals receivesClientKey [
        "d /home/${username}/.ssh 0700 ${username} users -"
      ];

      age.secrets =
        lib.optionalAttrs (receivesClientKey && hasPersonalKeyAge) {
          "ssh-id-ed25519-personal" = {
            file = personalKeyAge;
            path = "/home/${username}/.ssh/id_ed25519_personal";
            mode = "0600";
            owner = username;
            group = "users";
          };
        }
        // lib.optionalAttrs (receivesClientKey && hasWorkKeyAge) {
          "ssh-id-ed25519-work" = {
            file = workKeyAge;
            path = "/home/${username}/.ssh/id_ed25519_work";
            mode = "0600";
            owner = username;
            group = "users";
          };
        };
    };
}
