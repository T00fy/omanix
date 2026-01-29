{ pkgs, lib, config, ... }:
let
  cfg = config.omanix;
in
{
  options.omanix.font = lib.mkOption {
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
      (pkgs.runCommand "omanix-font" {} ''
        mkdir -p $out/share/fonts/truetype
        cp ${../../../assets/fonts/omanix.ttf} $out/share/fonts/truetype/
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
    };
  };
}
