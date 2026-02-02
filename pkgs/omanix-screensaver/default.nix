{
  lib,
  python3Packages,
  gtk4,
  gtk4-layer-shell,
  vte-gtk4,
  gobject-introspection,
  wrapGAppsHook,
}:

python3Packages.buildPythonApplication {
  pname = "omanix-screensaver";
  version = "1.0.0";
  format = "other"; # It's a script, not a setup.py module

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
    wrapGAppsHook
  ];

  # We don't have a setup.py, so we manually install the script
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp screensaver.py $out/bin/omanix-screensaver
    chmod +x $out/bin/omanix-screensaver
    runHook postInstall
  '';

  # The Critical LD_PRELOAD Fix
  # wrapGAppsHook handles GI_TYPELIB_PATH automatically, but we need to inject
  # the layer-shell library before Python starts.
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
