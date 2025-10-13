# Mako notifications
{ ... }:
{
  home.file.".config/mako/config".text = ''
    font=Inter 11
    width=320
    height=160
    margin=8
    padding=8
    border-size=2
    border-radius=6
    default-timeout=5000
    inner-margin=8
    outer-margin=8
    background-color=#1d2021cc
    text-color=#ebdbb2
    border-color=#3c3836
    progress-color=over #458588
    placement=top-right
    anchor=top-right
    layer=overlay
  '';
}

