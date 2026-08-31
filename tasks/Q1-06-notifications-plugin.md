# Q1-06: Notifications plugin

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q1-04
- **Blocks:** Q3-02, Q3-03
- **Size:** M

## Context
Omarchy 4.0.2 replaced Mako with the `omarchy.notifications` Quickshell plugin, built on
`Quickshell.Services.Notifications`. It renders notification popups, persists a history (last
~10, with sender avatars) to disk, and runs click-actions as safe argv. This supersedes
omanix's Mako module (`modules/home-manager/ui/mako.nix`), including its Do-Not-Disturb mode.
Under D1 the plugin id is `omanix.notifications`.

## Scope
**In scope:** the `omanix.notifications` plugin loading; popups rendering for incoming
notifications; persisted history with avatars; DND toggle wired to the bar DND indicator
(`shell/plugins/bar/indicators/Dnd.qml`); click-action handling.
**Out of scope:** the bar indicator glyph plumbing beyond DND (Q1-05); notification theming
(Q2-02); replacing `makoctl` keybindings in Hyprland (Q3-01); removing the Mako module (Q3-03).

## Implementation notes
- Source: `shell/plugins/notifications/` — `Service.qml` (large), `NotificationLogic.js`,
  `components/NotificationCard.qml`, `manifest.json`. Vendored by Q1-02; this ticket verifies
  load + behavior and wires DND/history storage.
- History persists to a state path; use `~/.local/state/omanix/...` per Q0-04 (renamed from
  omarchy's state dir). Confirm the write path is user-writable (not the Nix store).
- DND: expose a toggle over the plugin's IPC target `omanix.notifications` and reflect it in the
  bar DND indicator. Omanix Mako drove DND via `makoctl` keybinds — those move to shell IPC in
  Q3-01; this ticket provides the IPC surface.
- **D1:** IPC target and plugin id are `omanix.notifications` (rename via Q0-03 patch). Do not
  reference `omarchy.*` anywhere in seeded config.
- The plugin registers a freedesktop notification server — ensure no other notification daemon
  (mako) is running in the test session or they will conflict for the DBus name.

## Acceptance criteria
- [ ] `omanix.notifications` loads and a test notification (`notify-send "hi" "there"`) renders a popup.
- [ ] Notification history persists across shell restart and shows sender avatars where available; stored under `~/.local/state/omanix/`.
- [ ] DND can be toggled via `omanix-shell omanix.notifications <toggle-dnd or equivalent>` and popups are suppressed while active; the bar DND indicator reflects state.
- [ ] A notification with an action, when clicked, runs the action as argv (no shell injection).
- [ ] `nix flake check` passes.

## Testing
- In a Hyprland session with the shell running and mako NOT running: `notify-send -a TestApp "Title" "Body"` → popup appears.
- Toggle DND via IPC, repeat `notify-send`, confirm suppression; untoggle, confirm popups return.
- Restart the shell (`omanix-restart-shell`), open history, confirm prior notifications listed.

## References
- omarchy: `shell/plugins/notifications/` (`Service.qml`, `NotificationLogic.js`, `components/NotificationCard.qml`, `manifest.json`), `docs/notifications.md`, `shell/plugins/bar/indicators/Dnd.qml`
- omanix: `modules/home-manager/ui/mako.nix` (superseded)
