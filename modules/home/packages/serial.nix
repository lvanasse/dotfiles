{ ... }:
{
  flake.modules.homeManager."packages.serial" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Serial / device utilities
      home.packages = with pkgs; [
        tio
        usbutils
        pciutils
        lsof
        file
        util-linux
        socat
        picocom
        minicom
        screen
        openocd
        probe-rs-tools
        dfu-util
        avrdude
        esptool
        stm32flash
        moserial
        putty
      ];

      xdg.configFile."tio/config".text = ''
        [default]
        baudrate = 115200
        databits = 8
        parity = none
        stopbits = 1
        flow = none
        color = 10
        timestamp = true
        timestamp-format = iso8601
        log-directory = ~/serial-logs

        [new]
        auto-connect = new
        log = true
        color = 11

        [latest]
        auto-connect = latest
        log = true
        color = 12

        [usb-devices]
        pattern = ^usb([0-9]*)
        device = /dev/ttyUSB%m1
        baudrate = 115200
        log = true
      '';

      home.activation.createSerialLogsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.home.homeDirectory}/serial-logs"
      '';
    };
}
