{ lib }:
rec {
  # Remove the leading '#' from a hex string
  # Example: "#1a1b26" -> "1a1b26"
  stripHash = hex: lib.removePrefix "#" hex;

  # Convert Hex string to an Attribute Set of Integers
  # Example: "#1a1b26" -> { r = 26; g = 27; b = 38; }
  hexToRgb = hex:
    let
      h = stripHash hex;
      r = lib.fromHexString (builtins.substring 0 2 h);
      g = lib.fromHexString (builtins.substring 2 2 h);
      b = lib.fromHexString (builtins.substring 4 2 h);
    in { inherit r g b; };

  # Convert Hex to comma-separated Decimal RGB string
  # Example: "#ffffff" -> "255, 255, 255"
  hexToRgbDecimal = hex:
    let rgb = hexToRgb hex;
    in "${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}";

  # Convert Hex to CSS RGBA string
  # Example: "#ffffff" -> "rgba(255, 255, 255, 1.0)"
  hexToRgbaCss = hex:
    let rgb = hexToRgb hex;
    in "rgba(${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}, 1.0)";
}
