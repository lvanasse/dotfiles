{ ... }:
{
  flake.modules.nixos."services.mergerfs" =
    { pkgs, ... }:
    let
      data1Uuid = "2cfe8f44-9b6e-4d09-8d55-fe9506759d59"; # sdb1
      data2Uuid = "0650d6e7-9270-4301-bb20-bc2701ddfa8d"; # sdc1
      data3Uuid = "7679fbf2-0302-452b-8333-2d663e276554"; # sde1
      parity1Device = "/dev/disk/by-label/parity1"; # sda1
    in
    {
      environment.systemPackages = [ pkgs.mergerfs ];

      # Keep mountpoint directories present across activation/reload.
      systemd.tmpfiles.rules = [
        "d /mnt/data1 0755 root root -"
        "d /mnt/data2 0755 root root -"
        "d /mnt/data3 0755 root root -"
        "d /mnt/parity1 0755 root root -"
        "d /mnt/storage 0755 root root -"
        "d /mnt/data3/appdata 0755 root root -"
      ];

      # Data/parity disks by stable UUID (non-destructive; no repartitioning).
      fileSystems."/mnt/data1" = {
        device = "/dev/disk/by-uuid/${data1Uuid}";
        fsType = "xfs";
        options = [
          "nofail"
          "x-systemd.device-timeout=10s"
        ];
      };

      fileSystems."/mnt/data2" = {
        device = "/dev/disk/by-uuid/${data2Uuid}";
        fsType = "xfs";
        options = [
          "nofail"
          "x-systemd.device-timeout=10s"
        ];
      };

      fileSystems."/mnt/data3" = {
        device = "/dev/disk/by-uuid/${data3Uuid}";
        fsType = "xfs";
        options = [
          "nofail"
          "x-systemd.device-timeout=10s"
        ];
      };

      # Parity disk currently has filesystem issues. Keep as on-demand mount
      # so activation does not fail while repair is pending.
      fileSystems."/mnt/parity1" = {
        device = parity1Device;
        fsType = "xfs";
        options = [
          "nofail"
          "noauto"
          "x-systemd.automount"
          "x-systemd.device-timeout=10s"
        ];
      };

      # MergerFS pool mount - combines data disks into single /mnt/storage
      systemd.mounts = [
        {
          what = "/mnt/data1:/mnt/data2:/mnt/data3";
          where = "/mnt/storage";
          type = "fuse.mergerfs";
          options =
            "defaults,nonempty,allow_other,use_ino,cache.files=off,moveonenospc=true,dropcacheonclose=true,minfreespace=20G,fsname=mergerfs,category.create=mfs";
          wantedBy = [ "multi-user.target" ];
        }
      ];
    };
}
