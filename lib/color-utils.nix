{ lib }:
rec {
  # Remove the leading '#' from a hex string
  # Example: "#1a1b26" -> "1a1b26"
  stripHash = hex: lib.removePrefix "#" hex;

  # Convert Hex string to an Attribute Set of Integers
  # Example: "#1a1b26" -> { r = 26; g = 27; b = 38; }
  hexToRgb =
    hex:
    let
      h = stripHash hex;
      r = lib.fromHexString (builtins.substring 0 2 h);
      g = lib.fromHexString (builtins.substring 2 2 h);
      b = lib.fromHexString (builtins.substring 4 2 h);
    in
    {
      inherit r g b;
    };

  # Convert Hex to comma-separated Decimal RGB string
  # Example: "#ffffff" -> "255, 255, 255"
  hexToRgbDecimal =
    hex:
    let
      rgb = hexToRgb hex;
    in
    "${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}";

  # Convert Hex to CSS RGBA string
  # Example: "#ffffff" -> "rgba(255, 255, 255, 1.0)"
  hexToRgbaCss =
    hex:
    let
      rgb = hexToRgb hex;
    in
    "rgba(${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}, 1.0)";

  # Convert an { r, g, b } set of integers back to a lowercase hex string.
  # lib.toHexString is uppercase and unpadded ("5" not "05"), so pad and lower.
  # Example: { r = 26; g = 27; b = 38; } -> "#1a1b26"
  rgbToHex =
    { r, g, b }:
    let
      toHex2 =
        n:
        let
          h = lib.toLower (lib.toHexString n);
        in
        if builtins.stringLength h < 2 then "0" + h else h;
    in
    "#${toHex2 r}${toHex2 g}${toHex2 b}";

  # Linearly blend two hex colors per channel. pct is an integer 0-100:
  # 0 -> all hexA, 100 -> all hexB. Integer math only (deterministic).
  # Example: mix "#f7768e" "#e0af68" 50 -> "#eb927b"
  mix =
    hexA: hexB: pct:
    let
      a = hexToRgb hexA;
      b = hexToRgb hexB;
      blend = x: y: (x * (100 - pct) + y * pct) / 100;
    in
    rgbToHex {
      r = blend a.r b.r;
      g = blend a.g b.g;
      b = blend a.b b.b;
    };

  # Mix a color toward black / white by pct.
  darken = hex: pct: mix hex "#000000" pct;
  lighten = hex: pct: mix hex "#ffffff" pct;
}
