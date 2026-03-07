{ ... }:
{
  flake.modules.nixos."services.snapraid" =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.snapraid ];

      # Snapraid configuration - UUIDs to be filled after disk identification
      services.snapraid = {
        enable = true;
        parityFiles = [
          "/mnt/parity1/snapraid.parity"
        ];
        contentFiles = [
          "/mnt/data1/.snapraid.content"
          "/mnt/data2/.snapraid.content"
          "/mnt/data3/.snapraid.content"
        ];
        dataDisks = {
          d1 = "/mnt/data1";
          d2 = "/mnt/data2";
          d3 = "/mnt/data3";
        };
        exclude = [
          "*.unrecoverable"
          "/tmp/"
          "/lost+found/"
          ".Thumbs.db"
          ".DS_Store"
          "*.!sync"
          ".sync/"
          ".Trash-*/"
        ];
        sync.interval = "Tue,Fri 03:00";
        scrub = {
          interval = "weekly";
          plan = 10;
          olderThan = 7;
        };
      };
    };
}
