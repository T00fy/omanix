{ ... }:
{
  programs.mpv = {
    enable = true;

    config = {
      # Prevent grey/washed-out colors in fullscreen on Hyprland
      # (Hyprland doesn't fully support the Wayland color management protocol yet)
      target-colorspace-hint = false;
    };
  };
}
