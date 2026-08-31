# Q3-03: Remove/gate old-stack modules (waybar/walker/elephant/mako/swayosd/hyprlock/hypridle)

- **Phase:** 3
- **Status:** todo
- **Depends on:** Q3-01, Q3-02, Q2-03
- **Blocks:** none
- **Size:** M

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

## Acceptance criteria
- [ ] Listed modules are removed or gated off by default with a documented option.
- [ ] `walker` and `elephant` flake inputs (and their overlay/module wiring) are removed;
      `flake.lock` regenerated.
- [ ] No remaining references to the removed modules/inputs anywhere (`grep`).
- [ ] Theme system no longer generates configs for the removed tools.
- [ ] `nix flake check` passes and a full HM build succeeds.

## Testing
- `nix flake check`; `nix build .#homeManagerModules...` / a test HM activation builds.
- `grep -rnE "waybar|walker|elephant|mako|swayosd|hyprlock|hypridle" modules/ flake.nix`
  returns only intentional/gated references (ideally none).
- Runtime: a fresh session comes up with only the shell providing bar/notifications/OSD/lock/idle.

## References
- omarchy: retired-package list in `bin/omarchy-upgrade-to-quattro` (confirms these are dropped)
- omanix: `flake.nix`, `modules/home-manager/ui/*.nix`, `modules/home-manager/desktop/{hyprlock,hypridle,hyprpaper}.nix`, `modules/home-manager/theme/default.nix`
