{ ... }:
{
  flake.modules.nixos."server.mergerfs" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.mergerfs ];

      # MergerFS pool mount - combines data disks into single /mnt/storage
      fileSystems."/mnt/storage" = {
        device = "/mnt/data1:/mnt/data2:/mnt/data3";
        fsType = "fuse.mergerfs";
        options = [
          "defaults"
          "nonempty"
          "allow_other"
          "use_ino"
          "cache.files=off"
          "moveonenospc=true"
          "dropcacheonclose=true"
          "minfreespace=20G"
          "fsname=mergerfs"
          "category.create=mfs"
        ];
      };
    };
}
