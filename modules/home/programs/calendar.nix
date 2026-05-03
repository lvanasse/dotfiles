{ inputs, ... }:
{
  flake.modules.homeManager."programs.calendar" =
    {
      config,
      lib,
      ...
    }:
    let
      homeDir = config.home.homeDirectory;
      caldavPasswordAge = "${inputs.secrets}/calendar/infomaniak-caldav-password.age";
      hasCaldavPassword = builtins.pathExists caldavPasswordAge;
      caldavPasswordPath = "${homeDir}/.config/calendar/infomaniak-caldav-password";
    in
    {
      home.activation.ensureOrgCalendarDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${homeDir}/org"
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
