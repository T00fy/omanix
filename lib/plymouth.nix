{ lib }:

let
  inherit (import ./color-utils.nix { inherit lib; }) hexToRgb darken;

  # A palette hex -> a "r g b" triple of Plymouth floats (0.0-1.0), space-joined
  # for direct interpolation into the script's SetColor calls.
  # Example: "#1a1b26" -> "0.101961 0.105882 0.149020"
  rgbFloat =
    hex:
    let
      c = hexToRgb hex;
      f = n: toString (n / 255.0);
    in
    "${f c.r}, ${f c.g}, ${f c.b}";
in

# Render an omanix Plymouth "script"-module theme from a palette. Fully derived
# from the colors — no hand-authored art. The .plymouth carries a @themedir@
# placeholder that the build substitutes with the installed store dir; the two
# solid-color swatches (track.png / progress.png) are generated at build time
# and scaled in the script (see modules/nixos/plymouth.nix).
{
  colors,
  name ? "omanix",
}:

let
  bg = rgbFloat colors.background;
  # The bar track is a subtly-lightened-from-black shade of the background so it
  # reads against the screen without a hard border; the fill is the accent.
  track = darken colors.background 55;
in
{
  # Solid-color swatches the build materializes as 1x1 PNGs (see the module).
  trackColor = track;
  fillColor = colors.accent;

  plymouth = ''
    [Plymouth Theme]
    Name=${name}
    Description=Omanix palette-colored boot splash
    ModuleName=script

    [script]
    ImageDir=@themedir@
    ScriptFile=@themedir@/${name}.script
  '';

  # Plymouth script language: solid palette background + a centered progress bar
  # composed from two 1x1 solid-color swatches scaled to size. track.png is the
  # unfilled bar, progress.png (accent) is clipped to the boot progress.
  script = ''
    Window.SetBackgroundTopColor(${bg});
    Window.SetBackgroundBottomColor(${bg});

    bar.width = Math.Int(Window.GetWidth() / 4);
    bar.height = 6;
    bar.x = Window.GetX() + Math.Int((Window.GetWidth() - bar.width) / 2);
    bar.y = Window.GetY() + Math.Int(Window.GetHeight() * 0.72);

    track.sprite = Sprite(Image("track.png").Scale(bar.width, bar.height));
    track.sprite.SetX(bar.x);
    track.sprite.SetY(bar.y);
    track.sprite.SetZ(1);

    fill.sprite = Sprite();
    fill.sprite.SetX(bar.x);
    fill.sprite.SetY(bar.y);
    fill.sprite.SetZ(2);

    fun boot_progress(duration, progress) {
      w = Math.Int(bar.width * progress);
      if (w < 1) w = 1;
      fill.sprite.SetImage(Image("progress.png").Scale(w, bar.height));
    }
    Plymouth.SetBootProgressFunction(boot_progress);

    # Keep the bar visible during the (SDDM) password/boot-complete phases too.
    fun refresh() { }
    Plymouth.SetRefreshFunction(refresh);
  '';
}
