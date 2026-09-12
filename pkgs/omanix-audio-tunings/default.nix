{
  lib,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "omanix-audio-tunings";
  version = "1.0.0";

  src = lib.cleanSource ./.;

  dontConfigure = true;
  dontBuild = true;

  # Read-only tuning data consumed by omanix-audio-tuning (via OMANIX_AUDIO_TUNINGS).
  # A tuning is a directory declaring the hardware it matches and the sink it
  # expects, so new tunings drop in as data with no code change.
  installPhase = ''
    runHook preInstall
    dst="$out/share/omanix/audio"
    mkdir -p "$dst"
    install -Dm644 ${./filter-chain-host.conf} "$dst/filter-chain-host.conf"
    cp -r ${./tunings} "$dst/tunings"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Per-laptop PipeWire speaker tunings for Omanix";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
