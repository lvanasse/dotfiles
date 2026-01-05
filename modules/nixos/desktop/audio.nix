{ ... }:
{
  flake.modules.nixos.desktopAudio =
    { ... }:
    {
      # Audio configuration with PipeWire

      # Disable PulseAudio
      services.pulseaudio.enable = false;

      # Enable real-time kit
      security.rtkit.enable = true;

      # Enable PipeWire
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };
}
