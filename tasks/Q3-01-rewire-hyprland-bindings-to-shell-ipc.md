# Q3-01: Rewire Hyprland bindings to shell IPC

- **Phase:** 3
- **Status:** done
- **Depends on:** Q1-05, Q1-06, Q1-07, Q1-08, Q1-09, Q1-10, Q1-11, Q1-12, Q1-13
- **Blocks:** Q3-03, Q3-05
- **Size:** M

> **Partial:** the 5 notification keybinds (`makoctl …` → `omanix-shell notifications
> {dismissOne,dismissAll,toggleDnd,invokeLast,showHistory}`) were rewired in **Q1-06** when mako
> was removed. Remaining scope (menu/launcher/clipboard/emoji/lock/etc. binds) stays here.

> **Done:** rewired launcher (`SUPER+SPACE → omanix-menu`), apps (`SUPER+ALT+SPACE → omanix-menu
> apps`), emoji (`SUPER+CTRL+E → omanix-menu-emoji`), clipboard (`SUPER+CTRL+V →
> omanix-clipboard-open`), share (`SUPER+CTRL+S → omanix-menu trigger.share`), bar toggle
> (`SUPER+SHIFT+SPACE → omanix-toggle-bar`), lock (`SUPER+CTRL+L → omanix-system-lock`), and the
> system panels `SUPER+CTRL+{A,B,W}` → `omanix.{audio,bluetooth,network}` + new `SUPER+CTRL+{D,P}`
> → `omanix.{monitor,power}` (retiring the pavucontrol/bluetui/wlctl TUI launchers from
> `bindings.nix`). All via `omanix-shell shell toggle` (bar-widget-safe form) or the thin shims.
> **Media carve-out (decided):** the volume/brightness/mute/playerctl/audio-switch keys stay on
> `swayosd-client` — `omanix-osd` only *displays* and no producer CLI exists yet. That rewire +
> swayosd removal moved to **Q4-03** (documented in `tasks/Q4-03-audio-tuning.md`); Q3-03's
> swayosd removal now waits on it. Also left as-is (not this ticket): `SUPER+K →
> omanix-menu-keybindings` (walker-backed, no shell equiv yet — Q3-03) and `SUPER+CTRL+ALT+B →
> omanix-battery-remaining` (dangling — Q3-05). `nix flake check` passes.

## Context
In omarchy 4.0.2 the desktop is a single Quickshell process; keybindings no longer launch
discrete tools (walker/swayosd/mako) but instead drive the shell over IPC
(`omanix-shell <target> <method>`). Omanix's keybindings live in
`modules/home-manager/desktop/hyprland/bindings.nix` — Lua rendered via `mkLuaInline`,
dispatching to `omanix-*` scripts through helper builders (`mkBind`, `mkExec`,
`mkExecLocked`, `mkExecRepeatLocked`). This ticket repoints the launcher/clipboard/emoji/
panel/lock/OSD keybinds at the new shell, so the old daemons can be removed in Q3-03.

Do this only after the plugins those keybinds target are up (all Q1-05..Q1-13 ✅).

## Scope
**In scope:** edit `bindings.nix` so launcher, clipboard, emoji, per-panel toggles, lock,
and volume/brightness/media OSD keys call the shell (via the IPC CLI from Q1-04 and the
audio/OSD CLIs from Q1-07/Q1-14). Keep every binding's human description (it feeds the
keybindings viewer). Update the `extra*` binding extension points if their defaults changed.
**Out of scope:** removing the old modules/inputs (Q3-03); autostart (Q3-02); porting the
helper CLIs themselves (Q1-*); the bash menu surface (Q3-05).

## Implementation notes
- Reference omarchy binding intent in `default/hypr/bindings/{utilities,clipboard,media}.lua`:
  `SUPER+SPACE` → menu toggle, `SUPER+ALT+SPACE` → apps menu, `SUPER+CTRL+V` → clipboard,
  `SUPER+CTRL+E` → emojis, `SUPER+CTRL+{A,B,D,W,P}` → audio/bluetooth/monitor/network/power
  panels over shell IPC, lock via the shell lock plugin.
- Replace `omanix-launch-walker` / `omanix-menu` launcher calls with the shell menu toggle.
- Replace `swayosd-client` media/volume/brightness binds with the omanix OSD/audio CLIs
  (Q1-07 `omanix-osd`, Q1-14). Replace `makoctl` DND binds with the notifications plugin IPC.
- Replace the hyprlock launch (`omanix-lock-screen`) with the shell lock plugin invocation.
- D1: all targets/ids are `omanix.*` / `omanix-*`.
- Gotcha: number keys use X keycodes (`code:10`..); preserve them. Preserve `mkExecLocked`
  usage for binds that must work on the lock screen.
- Note the dangling `omanix-battery-remaining` ref at `bindings.nix:244` — leave it for Q3-05
  unless trivially replaceable by a shell/battery query here.

## Acceptance criteria
- [x] Launcher, apps, clipboard, emoji, per-panel, and lock keybinds dispatch to the shell
      (no residual `walker`/`makoctl`/`hyprlock` for these actions in `bindings.nix`). OSD/media
      keys are the documented Q4-03 carve-out — `swayosd-client` remains only in the media section.
- [x] Every rewired binding retains a description string.
- [x] `extra*` extension points still merge without eval errors.
- [x] `nix flake check` passes.

## Testing
- `nix flake check` and `nix eval` of the HM config render valid Lua.
- Runtime (Hyprland session with the shell running): press each rewired key and confirm the
  shell responds (menu opens, clipboard/emoji panels summon, panels toggle, lock engages,
  volume/brightness OSD shows).
- `grep -nE "walker|swayosd-client|makoctl|hyprlock" modules/home-manager/desktop/hyprland/bindings.nix`
  returns nothing for the rewired actions.
- Open the keybindings viewer and confirm descriptions render.

## References
- omarchy: `default/hypr/bindings/{utilities,clipboard,media}.lua`, `bin/omarchy-shell`, `bin/omarchy-osd`
- omanix: `modules/home-manager/desktop/hyprland/bindings.nix`
