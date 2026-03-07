{
  # Disko configuration for WDC WD10EZEX-00WN4A0 1TB HDD
  disko.devices = {
    disk = {
      media = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD10EZEX-00WN4A0_WD-WCC6Y5SD928X";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/data1";
              };
            };
          };
        };
      };
    };
  };
}
