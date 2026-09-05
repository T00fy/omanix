{
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "omanix-shell";
  version = "1.0.0";

  # In-repo committed snapshot, already renamed at vendor time (Q0-01/Q0-03).
  # No fetch, no source input, no build-time rename.
  src = lib.cleanSource ../../vendor/omanix-shell;

  dontConfigure = true;
  dontBuild = true;

  # Plain recursive copy — no text mutation (preserves embedded Nerd Font glyphs).
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/omanix/shell"
    cp -r ./. "$out/share/omanix/shell/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Vendored Quickshell desktop tree (QML + assets) for Omanix";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
