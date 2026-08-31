# Q1-12: Idle service plugin

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q1-04 (and functionally Q1-11 for the lock action)
- **Blocks:** Q3-02, Q3-03 (remove Hypridle)
- **Size:** M

## Context
Omarchy 4.0.2 handles idle behavior inside the shell via the `omarchy.idle` headless service
plugin, replacing the standalone `hypridle` daemon. Omanix today uses Hypridle
(`desktop/hypridle.nix`) with layered listeners driven by `omanix.idle.*` options:
screensaver → dim → lock → dpms → suspend, each with a configurable timeout.

This ticket brings up `omanix.idle` and maps omanix's existing `omanix.idle.*` option surface
onto the shell's idle configuration in `shell.json`, so users keep the same knobs while the
shell owns idle management.

## Scope
**In scope:** vendor + enable the `omanix.idle` service plugin; map `omanix.idle.*` options to
the `shell.json` `idle` block; ensure idle → screensaver, idle → lock (via Q1-11), and DPMS/
suspend transitions fire correctly.
**Out of scope:** removing `desktop/hypridle.nix` (Q3-03); the screensaver *content* (omanix
ships a custom `omanix-screensaver` — decide whether the shell's screensaver or the existing GTK
screensaver is used, and document; do not rebuild the screensaver here).

## Implementation notes
- Source: omarchy `shell/plugins/services/idle/{Service.qml,IdleModel.js,manifest.json}`,
  vendored by Q1-02 with D1 rename (`omarchy.idle` → `omanix.idle`).
- **Config mapping is the core work.** The default `shell.json` idle block is minimal:
  `"idle": { "screensaver": 150, "lock": 300 }` (seconds). Omanix's `omanix.idle.*` currently
  expresses more layers (dim, dpms, suspend). Decide the mapping:
  - Preserve omanix's option names as the user-facing surface; translate them into whatever the
    shell idle service supports in `shell.json`.
  - If the shell idle service supports fewer stages than hypridle did, document the reconciliation
    (e.g. dim folded into screensaver, dpms/suspend handled by systemd-logind settings instead).
    Read `shell/plugins/services/idle/IdleModel.js` to enumerate exactly which stages/keys the
    service honors, and base the mapping on that (don't assume).
- The lock stage depends on the lock plugin (Q1-11) — idle at the `lock` timeout should invoke
  `omanix.lock`. Verify the timeout value is read from `idle.lock`.
- **D2 note:** idle timeouts remain declared via `omanix.idle.*` (source of truth). The `idle`
  block is part of the **declared layer**: generate it into Q1-03's declarative base and reconcile
  it on every activation (declared wins) per Q1-03 § *Declarative reconcile contract* — do **not**
  seed it once into `shell.json`, or changing an `omanix.idle.*` option would silently stop taking
  effect after first activation. Runtime IPC changes to idle are the ephemeral overlay, reverted on
  rebuild.
- Screensaver: if using the shell's screensaver, ensure the `idle.screensaver` timeout triggers
  it; if keeping `omanix-screensaver`, wire the idle service to launch it and note this deviation.

## Acceptance criteria
- [ ] `omanix.idle` service plugin loads without error and is enabled by default.
- [ ] `omanix.idle.*` options map to `shell.json` `idle` keys; every currently-supported omanix
      idle knob has a documented destination (or a documented reconciliation if dropped/merged).
- [ ] The `idle` block lives in the declared base and is reconciled on activation: changing an
      `omanix.idle.*` option and rebuilding updates the live idle behavior (declared wins), per
      Q1-03's reconcile contract — not only on a fresh install.
- [ ] Idle to `screensaver` timeout activates the screensaver; idle to `lock` timeout locks the
      session (via Q1-11); DPMS off / suspend behavior is preserved (via the shell or documented
      logind fallback).
- [ ] Activity (mouse/key) before a stage cancels the pending transition.
- [ ] `nix flake check` passes; options doc builds.

## Testing
- Build: `nix flake check`, `nix build .#omanix-shell`.
- Runtime: in a Hyprland session, set short idle timeouts locally, confirm each stage fires in
  order (screensaver → lock → dpms/suspend as configured) and that moving the mouse cancels a
  pending transition. Confirm the lock stage shows the `omanix.lock` view.
- Eval mapping: `nix eval` the module to confirm `omanix.idle.*` values propagate into the seeded
  `shell.json` idle block.

## References
- omarchy: `shell/plugins/services/idle/Service.qml`,
  `shell/plugins/services/idle/IdleModel.js`, `shell/plugins/services/idle/manifest.json`,
  `config/omarchy/shell.json` (idle block), `docs/omarchy-shell.md`
- omanix: `modules/home-manager/desktop/hypridle.nix` (`omanix.idle` options),
  `pkgs/omanix-screensaver/`, seeded `shell.json` from Q1-03, lock from Q1-11
