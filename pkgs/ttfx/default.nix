{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

# ttfx — a dependency-free Rust port of terminaltexteffects that renders
# byte-identical frames as a single static binary. Omarchy swapped the Python
# `tte` for it (PR #6670) for a ~100x faster startup and higher frame rate; the
# omanix screensaver (omanix-screensaver / omanix-launch-screensaver) drives it
# the same way. Upstream: https://github.com/omacom/ttfx
rustPlatform.buildRustPackage rec {
  pname = "ttfx";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "ttfx";
    rev = "v${version}";
    hash = "sha256-bwFjC6ZkZibkgXjoYVH2VuqqeXklGR9kmRl2fTitWBU=";
  };

  # Vendored so the build stays offline; the crate has no git dependencies.
  cargoLock.lockFile = ./Cargo.lock;

  meta = with lib; {
    description = "Terminal text effects as a single static binary (Rust port of terminaltexteffects)";
    homepage = "https://github.com/omacom/ttfx";
    license = licenses.mit;
    mainProgram = "ttfx";
    platforms = platforms.linux;
  };
}
