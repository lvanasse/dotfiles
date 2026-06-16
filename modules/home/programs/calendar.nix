{ ... }:
{
  flake.modules.homeManager."programs.calendar" =
    {
      config,
      lib,
      ...
    }:
    let
      homeDir = config.home.homeDirectory;
      caldavPasswordPath = "${homeDir}/.config/calendar/infomaniak-caldav-password";
    in
    {
      home.activation.ensureOrgCalendarDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${homeDir}/org"
      '';

      home.file."org/reminders.org".text = ''
        * Mettre les poubelles et le recyclage au chemin
        <2026-05-03 Sun 17:00-18:00 +1w>

        * Mettre le composte au chemin
        <2026-05-05 Tue 21:00-22:00 +1w>

        * Payer le loyer
        <2026-05-31 Sun 16:00-17:00 +1m>
      '';

      xdg.configFile."calendar/README".text = ''
        Infomaniak CalDAV for Spacemacs/org-caldav

        Secret file expected by the config:
        ${caldavPasswordPath}

        CalDAV URL:
        https://sync.infomaniak.com/calendars/LV04107/

        Calendar ID:
        a0fe5b9b-1a59-4cbe-8b13-bd262bf0738b
      '';

      home.sessionVariables = {
        ORG_CALDAV_PASSWORD_FILE = caldavPasswordPath;
      };
    };
}
