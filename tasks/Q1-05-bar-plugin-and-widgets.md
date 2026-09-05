# Q1-05: Bar plugin + core bar widgets

- **Phase:** 1
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q3-01, Q3-02, Q3-03, Q5-02
- **Size:** L

## Context
Omarchy 4.0.2 replaced Waybar with the `omarchy.bar` Quickshell plugin — a full QML bar host
that drops pluggable widgets into `left`/`center`/`right` sections defined in `shell.json`.
This ticket brings that bar up in the vendored omanix shell so it renders in a Hyprland
session and supersedes omanix's Waybar module (`modules/home-manager/ui/waybar.nix`, run today
as a systemd user service toggled by Super+Shift+Space).

The bar and its widgets ship inside the vendored shell tree from Q1-02, so "bringing it up" is
mostly: confirm the plugin loads, seed a sensible default bar layout in `shell.json`, map the
existing omanix waybar modules onto the equivalent widgets, and verify rendering. Under D1 the
plugin id is `omanix.bar` (renamed from `omarchy.bar`).

## Scope
**In scope:** the `omanix.bar` plugin loading and rendering; the core widgets Workspaces,
ActiveWindow, Clock (+calendar panel), Indicators, KeyboardLayout, Microphone, SystemUpdate,
Tray, Spacer; a default `bar.layout` seeded into `shell.json` that reproduces omanix's current
waybar module set (workspaces, clock, mpris, network, pulseaudio, battery, bluetooth, tray,
screenrecord/idle-inhibit indicators); the `shell.json` `bar.position`/`bar.transparent` keys respected (driven by `omanix.quickshell.bar.*` options).
**Out of scope:** the `omanix-bar` CLI for live layout edits (that is Q1-14); theming the bar
(colors/`shell.toml` come from Q2-02); the OSD, notifications, network/bluetooth *panels* (own
tickets); removing the Waybar module (Q3-03).

## Implementation notes
- Widgets live under `shell/plugins/bar/widgets/*.qml` with adjacent `*.manifest.json`; bar
  indicators under `shell/plugins/bar/indicators/`. The bar itself is `shell/plugins/bar/Bar.qml`
  (large) + `BarModel.js` + `manifest.json`. These are vendored by Q1-02 — do not re-copy; this
  ticket configures and validates them.
- **Namespace:** shell **plugin ids / IPC targets** stay `omanix.bar` (from the D1 rename); the
  **Nix options** that configure the bar nest under `omanix.quickshell.bar.*` (consistent with
  Q1-03's `omanix.quickshell.*` shell namespace — see PORTING D6).
- Default layout: `bar.{id,position,transparent,centerAnchor,layout.{left,center,right}}` are
  part of the **declared layer** — generate them into Q1-03's declarative base from
  `omanix.quickshell.bar.*` options, so they are reconciled on every activation (declared wins),
  **not** seeded once. Follow Q1-03 § *Declarative reconcile contract*; do not write a one-shot
  default that later goes stale when the option changes. Per-widget settings are inline on each
  layout entry (e.g. `{ "id": "omanix.clock", "format": "HH:mm" }`).
- Map omanix waybar modules → shell widgets: workspaces→`omanix.workspaces`, clock→`omanix.clock`,
  tray→`omanix.tray`, custom screenrecord/idle-inhibit → the `omanix.indicators` composite with
  explicit `items = [ "ScreenRecording" "StayAwake" ]`. **Correction to the original note:**
  network/pulseaudio/battery/bluetooth are **standalone bar-widget plugins**
  (`omanix.network`/`omanix.audio`/`omanix.power`/`omanix.bluetooth`), **not** entries in the
  `omanix.indicators` composite — their panels are handled in Q1-13. mpris→`omanix.media`
  (deferred to Q1-13; the media service feeds that widget). Note the omanix `custom-voxtype`
  waybar CSS is dead (no module) — do not port. **Path correction:** the vendored bar plugin is at
  `plugins/bar/` (not `shell/plugins/bar/`).
- **D1:** widget ids and the bar id are `omanix.*`. The rename is applied by Q0-03's patch
  phase; this ticket must not hardcode `omarchy.*` ids in the seeded `shell.json`.
- Gotcha: widget QML embeds Nerd Font glyphs as raw multibyte chars — ensure fonts are present
  (omanix `core/fonts`) or glyphs render as tofu.

## Acceptance criteria
- [~] With the shell running, the `omanix.bar` plugin loads (visible in `omanix-shell shell listPlugins`) and a bar renders on screen. *(Impl complete: `bar.id = "omanix.bar"` seeded; runtime session not exercisable in this environment.)*
- [x] The seeded default `shell.json` produces a bar with at least: workspaces, active window, clock, tray, and status indicators (network/audio/battery/bluetooth), reproducing the omanix waybar content set. *(Verified: rendered `bar.layout` contains `omanix.workspaces`, `omanix.active-window`, `omanix.clock`, `omanix.indicators` [ScreenRecording, StayAwake], `omanix.tray`, `omanix.bluetooth`, `omanix.network`, `omanix.audio`, `omanix.power`; SystemUpdate/NightLight/Dictation omitted per Q0-05.)*
- [~] Clicking the clock opens its calendar panel; the Indicators widget shows live status glyphs. *(Runtime-only; not exercisable here.)*
- [~] `bar.position` and `bar.transparent` in `shell.json` are honored on shell restart. *(Runtime-only; keys are seeded from options.)*
- [x] The bar layout/position/transparent are driven by `omanix.quickshell.bar.*` options in the declared base: changing an option and rebuilding updates the bar (declared wins), even after a runtime `omanix-bar` edit to the same key (per Q1-03's reconcile contract). *(Options feed `declaredBase`; `jq -s '.[0] * .[1]'` replaces the declared `bar.layout` array wholesale each activation.)*
- [x] `nix flake check` passes; the module seeding `shell.json` evaluates. *(Verified: `nix flake check` all checks passed; `builtins.toJSON` of the base renders valid JSON with the expected `bar` shape and no `omarchy.*` ids.)*

## Testing
- `nix build .#<shell-or-config attr>` then activate/enter a Hyprland session with the shell autostarted (per Q1-03).
- `omanix-shell shell listPlugins --json | jq '.[] | select(.id=="omanix.bar")'` shows it enabled.
- Visual: bar renders; workspaces update when switching workspaces; clock click opens calendar; tray shows running tray apps.
- Edit `bar.position` to `bottom` in `~/.config/omanix/shell.json`, `omanix-restart-shell`, confirm the bar moves.

## References
- omarchy: `shell/plugins/bar/` (`Bar.qml`, `BarModel.js`, `manifest.json`, `widgets/*`, `indicators/*`), `config/omarchy/shell.json`, `docs/omarchy-shell.md`
- omanix: `modules/home-manager/ui/waybar.nix` (superseded), the default `shell.json` seeded by Q1-03
