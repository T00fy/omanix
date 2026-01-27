{ lib }:
{
  # Expose color utils
  colors = import ./color-utils.nix { inherit lib; };
  
  # Expose themes (data only, doesn't need lib)
  themes = import ./themes.nix;
}
