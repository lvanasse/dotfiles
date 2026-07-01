args@{ ... }:
let
  diskNames = if args ? diskNames then args.diskNames else null;
  allDisks = {
    main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S21JNXAG556540E";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
    fastTier = {
      type = "disk";
      device = "/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S12JNEAD201328N";
      content = {
        type = "gpt";
        partitions = {
          fast = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              extraArgs = [
                "-L"
                "ssd-fast"
              ];
              mountpoint = "/mnt/ssd";
              mountOptions = [
                "defaults"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
  selectedDisks =
    if diskNames == null then
      allDisks
    else
      builtins.listToAttrs (
        map (name: {
          inherit name;
          value = allDisks.${name};
        }) diskNames
      );
in
{
  # Disko configuration for server SSDs.
  # On an installed server, pass --arg diskNames '[ "fastTier" ]' to provision
  # only the fast-tier SSD.

  disko.devices = {
    disk = selectedDisks;
  };
}
