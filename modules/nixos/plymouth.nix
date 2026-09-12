{
  config,
  lib,
  pkgs,
  ...
}:
let
  omanixLib = import ../../lib { inherit lib; };
  cfg = config.omanix;

  slug = cfg.theme;
  themeName = "omanix-${slug}";
  rendered = omanixLib.renderPlymouthTheme {
    colors = omanixLib.themes.${slug}.colors;
    name = themeName;
  };

  # Build the active theme's splash into the store as a Plymouth themePackage.
  # Fully palette-derived: the two solid-color swatches are generated here and
  # scaled in the script (rendered.script), so there is no hand-authored art.
  # @themedir@ in the .plymouth is patched to the installed store dir.
  scriptFile = pkgs.writeText "${themeName}.script" rendered.script;
  plymouthFile = pkgs.writeText "${themeName}.plymouth" rendered.plymouth;
  themePkg =
    pkgs.runCommand "omanix-plymouth-${slug}" { nativeBuildInputs = [ pkgs.imagemagick ]; }
      ''
        d="$out/share/plymouth/themes/${themeName}"
        mkdir -p "$d"
        cp ${scriptFile} "$d/${themeName}.script"
        sed "s|@themedir@|$d|g" ${plymouthFile} > "$d/${themeName}.plymouth"
        magick -size 1x1 xc:'${rendered.trackColor}' "$d/track.png"
        magick -size 1x1 xc:'${rendered.fillColor}' "$d/progress.png"
      '';
in
{
  options.omanix.boot.plymouth.enable =
    lib.mkEnableOption "the Omanix palette-colored Plymouth boot splash"
    // {
      default = true;
      description = ''
        Whether to enable a Plymouth boot splash colored from the active
        {option}`omanix.theme`. Fully declarative: the splash is baked into the
        initrd at build time, so it changes only on `nixos-rebuild`. There is no
        runtime theme switcher — set {option}`omanix.theme` and rebuild.

        The host owns the bootloader; this module adds `quiet`/`splash` kernel
        params, but a compatible bootloader/initrd may be required for the splash
        to appear.
      '';
    };

  config = lib.mkIf (cfg.enable && cfg.boot.plymouth.enable) {
    boot.plymouth = {
      enable = true;
      themePackages = [ themePkg ];
      theme = themeName;
    };

    boot.kernelParams = [
      "quiet"
      "splash"
    ];
  };
}
