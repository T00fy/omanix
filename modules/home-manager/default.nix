{ ... }:
{
  imports = [
    ./theme
    ./core/fonts.nix
    ./core/gtk.nix
    ./desktop/hyprland/visuals.nix
    ./desktop/hyprpaper.nix
    ./ui/waybar.nix
    ./terminal/ghostty.nix
  ];
}
