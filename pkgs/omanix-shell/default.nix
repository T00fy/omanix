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
  # The default menu tree is omanix-owned content (D5: a Nix-shipped file, not
  # part of the vendored snapshot); install it where Menu.qml:defaultMenuPath
  # resolves ($OMANIX_PATH/shell/defaults/omanix-menu.jsonc).
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/omanix/shell"
    cp -r ./. "$out/share/omanix/shell/"
    install -Dm644 ${./defaults/omanix-menu.jsonc} "$out/share/omanix/shell/defaults/omanix-menu.jsonc"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Vendored Quickshell desktop tree (QML + assets) for Omanix";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
