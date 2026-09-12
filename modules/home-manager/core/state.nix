{ lib, omanixLib, ... }:
{
  # Runtime state root for omanix (~/.local/state/omanix). See
  # docs/state-layout.md for the canonical layout and the
  # declarative-vs-runtime ownership rule (decision D2 / risk R3).
  #
  # Created writable on activation — NEVER a Nix-store symlink, since the
  # shell and toggle scripts mutate files here. Only the base root is
  # created; feature subdirs (current/, toggles/, agents/usage/, …) are
  # created on demand by the features that own them as they land.
  home.activation.omanixStateDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${omanixLib.state.rootExpr}"
  '';
}
