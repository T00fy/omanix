{
  lib,
  stdenv,
  makeWrapper,
  bash,
  xdg-utils,
  # Configurable options passed from module
  browserFallback ? "firefox.desktop",
}:

stdenv.mkDerivation {
  pname = "omanix-scripts";
  version = "1.0.0";

  src = ./src;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin

    # ═══════════════════════════════════════════════════════════════════
    # Script: omanix-launch-browser
    # ═══════════════════════════════════════════════════════════════════
    cp $src/omanix-launch-browser.sh $out/bin/omanix-launch-browser
    chmod +x $out/bin/omanix-launch-browser

    wrapProgram $out/bin/omanix-launch-browser \
      --set OMANIX_BROWSER_FALLBACK "${browserFallback}" \
      --prefix PATH : ${lib.makeBinPath [ bash xdg-utils ]}
  '';

  meta = with lib; {
    description = "Core logic scripts for Omanix desktop environment";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
