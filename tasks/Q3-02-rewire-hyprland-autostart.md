# Q3-02: Rewire Hyprland autostart (drop old daemons)

- **Phase:** 3
- **Status:** todo
- **Depends on:** Q1-03, Q1-06, Q1-07, Q1-10
- **Blocks:** Q3-03
- **Size:** S

> **Partial:** the `mako` autostart (`hl.exec_cmd("mako")`) was removed in **Q1-06** when mako
> was retired. The `hyprpolkitagent` autostart was **gated on `!omanix.quickshell.enable` in
> Q1-13** (so `omanix.polkit` is the sole agent when the shell runs) — this ticket should finish
> that (either drop the line entirely, or keep the gated form once the shell is the only path).
> Remaining daemons (swayosd-server, swaybg, cliphist, …) stay here.

## Context
Omanix starts the old desktop daemons from `modules/home-manager/desktop/hyprland/
autostart.nix` via `hl.on("hyprland.start", ...)` + `hl.exec_cmd(...)`: currently mako,
swayosd-server, hyprpolkitagent, cliphist, swaybg. Under Quickshell all of these are hosted
inside the shell process (notifications, OSD, polkit, clipboard, background). The shell
itself is autostarted by the session integration module (Q1-03). This ticket removes the
now-redundant autostarts so nothing double-runs.

## Scope
**In scope:** remove/replace the mako, swayosd-server, hyprpolkitagent, swaybg autostart
lines in `autostart.nix`; confirm the shell autostart (from Q1-03) is present and ordered
correctly; keep any autostart still required (e.g. cliphist store watcher if the clipboard
plugin relies on it — verify against Q1-09).
**Out of scope:** module removal (Q3-03); keybinding rewiring (Q3-01).

## Implementation notes
- Cross-check omarchy: the shell replaces hyprpaper/swaybg (`omanix.background`), mako
  (`omanix.notifications`), swayosd (`omanix.osd`), polkit agent (`omanix.polkit`).
- cliphist: confirm whether Q1-09's clipboard plugin still needs a `cliphist store` watcher
  running (omarchy's clipboard plugin shells out to `cliphist`/`wl-clipboard`). If yes, keep
  that autostart; if the plugin manages it, remove it.
- `omanix.hyprland.extraAutostart` must still append cleanly.
- Ensure ordering: the shell should start before things that IPC into it.

## Acceptance criteria
- [ ] mako, swayosd-server, hyprpolkitagent, swaybg are no longer autostarted from `autostart.nix`.
- [ ] The Quickshell shell is autostarted exactly once (from Q1-03), no duplicate.
- [ ] cliphist autostart decision made and documented in the ticket/commit.
- [ ] `nix flake check` passes.

## Testing
- `nix flake check`.
- Runtime: log into a fresh Hyprland session; confirm exactly one shell process runs
  (`pgrep -a quickshell`), notifications/OSD/background/polkit all work, and no
  mako/swayosd/hyprpolkitagent/swaybg processes are running (`pgrep -a mako swayosd swaybg hyprpolkitagent`).

## References
- omarchy: `default/hypr/apps/omarchy-shell.lua`, shell plugins `background/notifications/osd/polkit`
- omanix: `modules/home-manager/desktop/hyprland/autostart.nix`
