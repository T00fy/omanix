# Q1-12: Idle service plugin

- **Phase:** 1
- **Status:** done
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

## Resolution

The vendored `omanix.idle` service (`plugins/services/idle/`, `keepLoaded`, IPC target `idle`)
honors **only** `idle.screensaver` and `idle.lock` (seconds); it shells out to
`omanix-launch-screensaver` / `omanix-system-lock` / `omanix-system-wake` and tracks the running
screensaver via Hyprland window/layer events. Delivered:

- **Config mapping (`desktop/quickshell.nix`):** added an `idle` block to `declaredBase` mapping
  `omanix.idle.screensaver.timeout` → `idle.screensaver` and `omanix.idle.lock.timeout` →
  `idle.lock`. **D6 decision:** kept the legacy `omanix.idle.*` namespace as the user-facing
  surface (no `omanix.quickshell.idle.*`). A disabled stage (`enable = false`) is expressed as a
  "never" sentinel (`86400`) because the shell falls back to its built-in 150/300 defaults when a
  key is omitted, so omission cannot disable a stage. Reconciled by Q1-03's existing deep-merge —
  no activation change. Verified via HM eval: `screensaver.timeout=111` + `lock.enable=false`
  renders `{ "screensaver": 111, "lock": 86400 }`.
- **Stage reconciliation:** `dim`/`dpms`/`suspend` have no shell equivalent and **stay on
  hypridle**. `desktop/hypridle.nix` is gated on `omanix.quickshell.enable`: when the shell is
  active it drops hypridle's screensaver + lock listeners (shell owns them; avoids double-fire)
  and points `lock_cmd` at `omanix-system-lock`, keeping only dim/dpms/suspend. Full hypridle
  retirement + any logind migration is Q3-03.
- **Screensaver tracking (recorded vendored edit):** omanix's screensaver is a GTK **layer-shell**
  overlay (namespace `omanix-screensaver`), invisible to the upstream `openwindow`/window-class
  tracking. Edited `Service.qml` to also track it via Hyprland `openlayer`/`closelayer` on that
  namespace (`screensaverLayerCount`/`screensaverPresentCount`); logged in `vendor/PROVENANCE.md`.
- **Glue scripts (`pkgs/omanix-scripts`):** `omanix-launch-screensaver` (runs the GTK screensaver
  with the declared logo, baked via the existing `screensaverLogo` param), `omanix-system-lock`
  (`omanix-shell lock lock` + screensaver pkill), `omanix-system-wake` (`hyprctl dispatch dpms
  on`). The latter two also resolve Q1-11 dangling refs.

Screensaver *content* was not rebuilt (kept the GTK `omanix-screensaver`). Media-key/idle keybind
rewiring and hyprlock/hypridle removal remain Q3-01/Q3-03. Screensaver→lock sequencing, dismissal,
and DPMS/suspend are runtime-only to verify.

## Acceptance criteria
- [x] `omanix.idle` service plugin loads without error and is enabled by default. *(manifest
      `keepLoaded`, not in `disabledPlugins`; runtime load not exercised here.)*
- [x] `omanix.idle.*` options map to `shell.json` `idle` keys; every currently-supported omanix
      idle knob has a documented destination. *(screensaver/lock → shell; dim/dpms/suspend →
      retained hypridle; disabled → sentinel.)*
- [x] The `idle` block lives in the declared base and is reconciled on activation (declared wins),
      per Q1-03's reconcile contract — not only on a fresh install.
- [x] Idle to `screensaver` timeout activates the screensaver; idle to `lock` timeout locks the
      session (via Q1-11); DPMS off / suspend behavior is preserved (retained hypridle listeners).
      *(Wiring complete; sequencing is runtime-only to verify.)*
- [x] Activity (mouse/key) before a stage cancels the pending transition. *(`IdleMonitor` →
      `handleActiveSignal` → `cancelIdleCycle`; unchanged upstream logic.)*
- [x] `nix flake check` passes; options doc builds.

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
