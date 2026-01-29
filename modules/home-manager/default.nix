{ ... }:
{
  imports = [
    ./theme
    ./scripts.nix
    ./core/fonts.nix
    ./core/gtk.nix
    ./core/xcompose.nix
    ./core/shell.nix
    ./core/git.nix
    ./core/languages.nix  # <-- new
    ./apps/firefox.nix
    ./apps/neovim.nix
    ./desktop/hyprland/autostart.nix
    ./desktop/hyprland/envs.nix
    ./desktop/hyprland/visuals.nix
    ./desktop/hyprland/bindings.nix
    ./desktop/hyprland/input.nix
    ./desktop/hyprland/rules.nix
    ./desktop/hyprpaper.nix
    ./desktop/hypridle.nix
    ./desktop/hyprlock.nix
    ./ui/waybar.nix
    ./terminal/ghostty.nix
  ];
}
