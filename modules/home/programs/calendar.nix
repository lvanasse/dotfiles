{ config, lib, ... }:
let
  # Toggle to enable once server URL and credentials are known
  enableCalDAV = false;
in
{
  # vdirsyncer for CalDAV/CardDAV sync (disabled until configured)
  services.vdirsyncer = lib.mkIf enableCalDAV {
    enable = true;
    frequency = "hourly";
    # You can manage config via xdg.configFile if you prefer.
  };

  # khal terminal calendar (optional)
  programs.khal = lib.mkIf enableCalDAV {
    enable = true;
  };

  # Example vdirsyncer config (fill and then set enableCalDAV = true above)
  xdg.configFile."vdirsyncer/config" = lib.mkIf enableCalDAV {
    text = ''
      [general]
      status_path = "${config.home.homeDirectory}/.vdirsyncer/status/"

      [pair cal]
      a = "cal_remote"
      b = "cal_local"
      collections = ["from a", "from b"]

      [storage cal_remote]
      type = "caldav"
      url = "https://caldav.example.com/remote.php/dav/calendars/USERNAME/"
      username = "mail@ludovicvanasse.com"
      password = ""  # Use 'password_command' with secret-tool/pass for security
      # password_command = ["secret-tool", "lookup", "calendar", "ludovic"]

      [storage cal_local]
      type = "filesystem"
      path = "${config.home.homeDirectory}/.calendars/"
      fileext = ".ics"
    '';
  };
}
