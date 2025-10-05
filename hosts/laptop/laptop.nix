{ hostname, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  # Set hostname
  networking.hostName = hostname;

  # Boot configuration
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Laptop-specific features
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # SSH agent for laptop
  programs.ssh.startAgent = true;
  users.users.ludovic.linger = true;

  # Deploy the same personal SSH key via agenix (add laptop host key to
  # recipients later and rekey)
  age.secrets = {
    "ssh-id_ed25519_personal" = {
      file = "${inputs.secrets}/ssh/id_ed25519_personal.age";
      path = "/home/ludovic/.ssh/id_ed25519_personal";
      mode = "0600";
      owner = "ludovic";
      group = "users";
    };
    "ssh-id_ed25519_work" = {
      file = "${inputs.secrets}/ssh/id_ed25519_work.age";
      path = "/home/ludovic/.ssh/id_ed25519_work";
      mode = "0600";
      owner = "ludovic";
      group = "users";
    };
  };

  # Passwordless auth using the single public key
  users.users.ludovic.openssh.authorizedKeys.keys = [
    (builtins.readFile "${inputs.secrets}/keys/id_ed25519_personal.pub")
    (builtins.readFile "${inputs.secrets}/keys/id_ed25519_work.pub")
  ];
}
