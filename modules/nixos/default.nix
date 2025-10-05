# Main NixOS configuration modules
_: {
  imports = [
    ./core
    ./desktop
    ./services
    ./programs
  ];
}
