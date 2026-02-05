{
  lib,
  stdenv,
  makeWrapper,
  bash,
  xdg-utils,
  hyprland,
  jq,
  coreutils,
  # Configurable options
  browserFallback ? "firefox.desktop",
}:

stdenv.mkDerivation {
  pname = "omanix-scripts";
  version = "1.0.0";
  
  # Point to the root of the package directory so we can access ./src
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  # We don't need a build phase for shell scripts
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin

    # ═══════════════════════════════════════════════════════════════════
    # 1. omanix-launch-browser
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-browser.sh $out/bin/omanix-launch-browser
    chmod +x $out/bin/omanix-launch-browser
    wrapProgram $out/bin/omanix-launch-browser \
      --set OMANIX_BROWSER_FALLBACK "${browserFallback}" \
      --prefix PATH : ${lib.makeBinPath [ bash xdg-utils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 2. omanix-launch-or-focus
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-or-focus.sh $out/bin/omanix-launch-or-focus
    chmod +x $out/bin/omanix-launch-or-focus
    wrapProgram $out/bin/omanix-launch-or-focus \
      --prefix PATH : ${lib.makeBinPath [ bash hyprland jq coreutils ]}
  '';

  meta = with lib; {
    description = "Core logic scripts for Omanix desktop environment";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
