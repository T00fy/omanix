# Q3-03: Remove/gate old-stack modules (waybar/walker/elephant/mako/swayosd/hyprlock/hypridle)

- **Phase:** 3
- **Status:** done
- **Depends on:** Q3-01, Q3-02, Q2-03
- **Blocks:** none
- **Size:** M

> **Partial:** the **mako** module (`ui/mako.nix` + its import) was removed in **Q1-06** — omarchy
> 4.0.2 dropped mako and its notifications plugin fully replaces it. Remaining modules
> (waybar/walker/elephant/swayosd/hyprlock/hypridle) stay here.

## Context
Once the Quickshell shell provides the bar, launcher, notifications, OSD, lock, and idle
(Phase 1) and keybinds/autostart drive it (Q3-01, Q3-02), the discrete-tool modules are
dead. This ticket removes (or option-gates for a transition period) the omanix modules and
their flake inputs.

Old-stack modules:
`modules/home-manager/ui/{waybar,walker,elephant,mako,swayosd}.nix`,
`modules/home-manager/desktop/{hyprlock,hypridle}.nix` (and `hyprpaper.nix` if the background
plugin fully replaces it).

## Scope
**In scope:** remove or gate the listed modules; remove their imports from the HM module
aggregator; drop now-unused flake inputs (`walker`, `elephant`) and any overlay/`_module.args`
wiring for them in `flake.nix`; remove dead theming consumers for these tools (waybar CSS,
walker CSS, mako, swayosd CSS) from the theme propagation; delete their assets if unused
(`assets/branding/walker-layout.xml`).
**Out of scope:** the shell replacements (Phase 1); theming of the shell (Phase 2).

## Implementation notes
- Verify each replacement is confirmed working (its Q1 ticket ✅) before deleting the
  counterpart. Prefer a brief transition where modules are gated behind an option
  (e.g. `omanix.legacyShell.enable = false` by default) if you want a fallback; otherwise
  delete outright.
- `flake.nix` currently imports `walker`+`elephant` HM modules and wires overlays — remove
  those inputs and the `homeManagerModules.default` imports referencing them, plus lock file
  entries (`nix flake lock`).
- Recon flagged a `custom-voxtype` CSS block in waybar with no matching module — it dies with
  waybar; no action needed beyond deletion.
- Theme propagation: the recon lists 17 theme consumers; waybar/walker/mako/swayosd are among
  them. Remove those consumers so `nix flake check` doesn't reference deleted modules.
- Keep hyprpaper only if the background plugin (Q1-10) does not fully own the wallpaper;
  otherwise remove and drop swaybg/hyprpaper.
- D1: N/A (these are native omanix modules being deleted).

## Resolution
**Decision (with user): make Quickshell the default** — deleted the fully-replaced modules
rather than gating them. Removed `ui/{waybar,walker,elephant}.nix` + `desktop/{hyprlock,hyprpaper}.nix`
and their imports; deleted `assets/branding/walker-layout.xml` and `docs/{waybar,walker,hyprlock}.md`.
Their theme CSS/config generators died with the files (theme propagation is pull-based, so
`theme/default.nix` needed no change). Dropped the `walker`/`elephant` **flake inputs** +
destructures + the `walker.homeManagerModules` import; `nix flake lock` removed all seven
`walker`/`elephant` lock nodes. De-walkered `scripts/default.nix` and `pkgs/omanix-scripts/default.nix`
(removed the `omanix-launch-walker` derivation and the now-unused `walker`/`waybar`/`hyprlock`/`swaybg`/`bitwarden-cli`/`envsubst`
function params + the `swaybg`/`envsubst` runtime PATH entries).

`omanix.quickshell.enable` flipped to `default = true` (kept as a master switch). `autostart.nix`
lost the `!qs` old-daemon list (always launches the shell now); `rules.nix` lost the dead
`walker`/`waybar` layer rules.

**`SUPER+K` keybindings viewer rewired to the shell** (user decision): new shared
`omanix-menu-dmenu` helper packs stdin options into an `omanix.menu` dmenu-mode payload
(`mode:"select"`, `selectionFile`/`doneFile` round-trip, no QML change) and returns the pick;
`omanix-menu-keybindings` now emits tab-separated `\t<keycombo>\t<action>` rows into it (dropped
the walker `%-35s → %s` line + Pango escaping). `omanix-menu-style` rewritten to pick a theme via
the same helper → `omanix-theme-set` → `omanix-theme-bg-switcher` (dropped the swaybg/glow legacy
preview picker).

**Retired `omanix-lock-screen`** (it launched the deleted hyprlock): menu `system.lock` repointed
to `omanix-system-lock`. Its bitwarden-lock/xkb-reset are not carried over (already flagged in Q1-11).

**Kept swayosd.nix + hypridle.nix** (they still own duties): swayosd media/brightness binds await
**Q4-03**; `hypridle.nix` simplified to dim/dpms/suspend only (`quickshellOwnsIdle`/`hyprlockCmd`
conditionals removed, `lock_cmd = omanix-system-lock`) — screensaver+lock are the shell's.

Cleared the incidental waybar signals too: `omanix-cmd-screenrecord` now refreshes the shell's
recording indicator via `omanix-shell -q omanix.indicators refresh`; `omanix-toggle-idle`'s dead
`refresh_waybar` no-op was dropped.

**Deferred:** `omanix-scale.sh` still swaps waybar config variants for the HiDPI/Moonlight scaled
desktop. Porting that scale subsystem to the Quickshell bar is a standalone follow-up (its waybar
`pkill`/`systemctl restart` calls no-op harmlessly with waybar gone); tracked with the scale work,
not this cleanup.

## Acceptance criteria
- [x] Listed modules are removed (Quickshell is now the default; no gating fallback).
- [x] `walker` and `elephant` flake inputs (and their module wiring) are removed;
      `flake.lock` regenerated (zero `walker`/`elephant` nodes).
- [x] No remaining references to the removed modules/inputs anywhere (`grep` clean apart from
      `omanix-scale.sh`'s deferred waybar-variant machinery + one descriptive comment).
- [x] Theme system no longer generates configs for the removed tools (generators died with the files).
- [x] `nix flake check` passes; `omanix-scripts` + `omanix-shell` build. Full HM
      activation is runtime-only per the no-sandbox rule (user runs `nixos-rebuild switch`).

## Testing
- `nix flake check`; `nix build .#homeManagerModules...` / a test HM activation builds.
- `grep -rnE "waybar|walker|elephant|mako|swayosd|hyprlock|hypridle" modules/ flake.nix`
  returns only intentional/gated references (ideally none).
- Runtime: a fresh session comes up with only the shell providing bar/notifications/OSD/lock/idle.

## References
- omarchy: retired-package list in `bin/omarchy-upgrade-to-quattro` (confirms these are dropped)
- omanix: `flake.nix`, `modules/home-manager/ui/*.nix`, `modules/home-manager/desktop/{hyprlock,hypridle,hyprpaper}.nix`, `modules/home-manager/theme/default.nix`
