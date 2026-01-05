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

  personalAge = "${inputs.secrets}/ssh/id_ed25519_personal.age";
  workAge = "${inputs.secrets}/ssh/id_ed25519_work.age";

  hasPersonalPub = builtins.pathExists personalPub;
  hasWorkPub = builtins.pathExists workPub;

  hasPersonalAge = builtins.pathExists personalAge;
  hasWorkAge = builtins.pathExists workAge;
in
{
  flake.modules.nixos.servicesSshKeys =
    { ... }:
    {
      # gnome-keyring already starts gcr-ssh-agent; disable the legacy ssh-agent to avoid conflicts.
      programs.ssh.startAgent = lib.mkForce false;

      # Passwordless auth using the same public keys across hosts (when present).
      users.users.${username}.openssh.authorizedKeys.keys =
        (lib.optionals hasPersonalPub [ (builtins.readFile personalPub) ])
        ++ (lib.optionals hasWorkPub [ (builtins.readFile workPub) ]);

      # Deploy SSH keys via agenix (system-level) using encrypted files from the
      # private secrets repository. Decrypts using host SSH keys by default.
      age.secrets =
        (
          if hasPersonalAge then
            {
              "ssh-id_ed25519_personal" = {
                file = personalAge;
                path = "/home/${username}/.ssh/id_ed25519_personal";
                mode = "0600";
                owner = username;
                group = "users";
              };
            }
          else
            { }
        )
        // (
          if hasWorkAge then
            {
              "ssh-id_ed25519_work" = {
                file = workAge;
                path = "/home/${username}/.ssh/id_ed25519_work";
                mode = "0600";
                owner = username;
                group = "users";
              };
            }
          else
            { }
        );
    };
}
