# System services modules
_: {
  imports = [
    ./flatpak.nix
    ./ssh.nix
    ./printing.nix
    ./virtualization.nix
    ./keyring.nix
    ./power.nix
    ./secrets.nix
  ];
}
