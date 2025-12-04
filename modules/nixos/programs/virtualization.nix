{
  services.printing.enable = true;
  virtualisation.docker.enable = true;

  # VirtualBox host
  virtualisation.virtualbox.host.enable = true;

  # Put your user into the vboxusers group so it can use VirtualBox
  users.extraGroups.vboxusers.members = [ "ludovic" ];
}
