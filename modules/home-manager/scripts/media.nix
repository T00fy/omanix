{ pkgs, ... }:
{
  home.packages = with pkgs; [
    playerctl
    brightnessctl
    wireplumber
    pavucontrol
  ];
}
