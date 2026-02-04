{ pkgs, lib, ... }:
{
  options.omanix.font = lib.mkOption {
    type = lib.types.str;
    default = "JetBrainsMono Nerd Font";
    description = "The primary monospace font used across the system.";
  };

  config = {
    home.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      liberation_ttf
      inter
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      (pkgs.runCommand "omanix-font" { } ''
        mkdir -p $out/share/fonts/truetype
        cp ${../../../assets/fonts/omanix.ttf} $out/share/fonts/truetype/
      '')
    ];

    fonts.fontconfig = {
      enable = true;

      defaultFonts = {
        serif = [ "Liberation Serif" ];
        sansSerif = [ "Liberation Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };
}
