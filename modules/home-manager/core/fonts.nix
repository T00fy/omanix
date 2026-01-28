{ pkgs, lib, config, ... }:
let
  cfg = config.omarchy;
in
{
  options.omarchy.font = lib.mkOption {
    type = lib.types.str;
    default = "JetBrainsMono Nerd Font";
    description = "The primary monospace font used across the system.";
  };

  config = {
    home.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      liberation_ttf          # Required by Omarchy config
      inter                   # Used by some UI elements
      noto-fonts              # Fallbacks
      noto-fonts-cjk-sans     # CJK Fallbacks
      noto-fonts-color-emoji  # Emoji
      font-awesome            # Icons
      (pkgs.runCommand "omarchy-font" {} ''
        mkdir -p $out/share/fonts/truetype
        cp ${../../../assets/fonts/omarchy.ttf} $out/share/fonts/truetype/
      '')
    ];

    fonts.fontconfig = {
      enable = true;
      
      # Match Omarchy's fonts.conf logic
      defaultFonts = {
        serif = [ "Liberation Serif" ];
        sansSerif = [ "Liberation Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };

      # ADD THESE - Critical for proper rendering!
      antialias = true;
      hinting = {
        enable = true;
        autohint = false;  # Use font's native hinting
        style = "slight";  # Good for modern displays; try "medium" if text looks fuzzy
      };
      subpixel = {
        rgba = "rgb";      # Change to "bgr" if colors look wrong
        lcdfilter = "default";
      };
    };
  };
}
