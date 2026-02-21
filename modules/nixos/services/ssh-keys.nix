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

  hasPersonalPub = builtins.pathExists personalPub;
  hasWorkPub = builtins.pathExists workPub;
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

      # SSH keys are now managed manually in ~/.ssh/
      # Generate with: ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal
    };
}
