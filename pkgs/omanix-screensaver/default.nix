{
  lib,
  python3Packages,
  gtk4,
  gtk4-layer-shell,
  vte-gtk4,
  gobject-introspection,
  wrapGAppsHook4,
}:

python3Packages.buildPythonApplication {
  pname = "omanix-screensaver";
  version = "1.0.0";
  format = "other";

  src = ./.;

  propagatedBuildInputs = with python3Packages; [
    pygobject3
    terminaltexteffects
  ];

  buildInputs = [
    gtk4
    gtk4-layer-shell
    vte-gtk4
  ];

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook4
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp screensaver.py $out/bin/omanix-screensaver
    chmod +x $out/bin/omanix-screensaver
    runHook postInstall
  '';

  preFixup = ''
    makeWrapperArgs+=(
      "--set" "LD_PRELOAD" "${gtk4-layer-shell}/lib/libgtk4-layer-shell.so"
    )
  '';

  meta = with lib; {
    description = "GTK4 Layer Shell Screensaver using Terminal Text Effects";
    license = licenses.mit;
    mainProgram = "omanix-screensaver";
    platforms = platforms.linux;
  };
}
