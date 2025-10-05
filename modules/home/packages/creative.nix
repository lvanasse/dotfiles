# Creative and design packages
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    # CAD and design
    kicad-small
    freecad

    # Wine for Windows applications
    wine
    winetricks
    mono

    # Serial communication
    moserial
    putty

    # Containers
    docker
  ];
}
