{ pkgs, ... }:
{
  home.packages = with pkgs; [
    satty
    wayfreeze
    grim
    slurp
    wl-clipboard
    libnotify
    hyprpicker
    blueman
    bitwarden-cli
    procps
  ];
}
