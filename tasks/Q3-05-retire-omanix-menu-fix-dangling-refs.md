# Q3-05: Retire/repurpose `omanix-menu.sh`; fix dangling script refs

- **Phase:** 3
- **Status:** todo
- **Depends on:** Q3-01
- **Blocks:** none
- **Size:** S

## Context
Omanix's "control panel" today is a bash + Walker-dmenu surface,
`pkgs/omanix-scripts/src/omanix-menu.sh` (nested Apps/Learn/Trigger/Style/Setup/System). The
Quickshell shell provides its own hierarchical menu (`omanix.menu`), so this bash surface is
largely superseded. This ticket decides its fate and cleans up two dangling script
references surfaced during recon:

- `modules/home-manager/ui/walker.nix:222` → `command = "omanix-restart-walker";` (walker is
  being removed in Q3-03; this restart command does not exist in `src/`).
- `modules/home-manager/desktop/hyprland/bindings.nix:244` → `omanix-battery-remaining` (not
  present in `src/`).

## Scope
**In scope:** decide keep-as-fallback vs remove for `omanix-menu.sh` and its
`omanix-menu-{keybindings,style}` helpers; resolve both dangling references; ensure no binding
or module points at a nonexistent script.
**Out of scope:** the shell menu itself (Q1-08); walker module removal (Q3-03, but coordinate).

## Implementation notes
- Recommended: retire `omanix-menu.sh` once the shell menu (Q1-08) covers its entries; if a
  headless/fallback menu is still wanted, keep it but repoint its launcher off walker.
- `omanix-restart-walker`: dies with the walker module in Q3-03 — remove the reference (the
  whole `walker.nix` is being removed there, so this may be handled by Q3-03; confirm no other
  references remain).
- `omanix-battery-remaining`: the shell's battery service/widget now owns battery state.
  Either (a) drop the keybind (battery is visible in the bar), or (b) reimplement the query
  against the shell/UPower and keep the notify. Pick one and document it.
- D1: `omanix-*` throughout.

## Acceptance criteria
- [ ] Decision on `omanix-menu.sh` (retire or fallback) is implemented and noted in the commit.
- [ ] No reference anywhere to `omanix-restart-walker` or any removed walker command.
- [ ] `omanix-battery-remaining` reference is resolved (removed or backed by a real command).
- [ ] `grep` across `modules/` + `pkgs/` finds no invocation of a script absent from
      `pkgs/omanix-scripts/src/` (and not provided elsewhere).
- [ ] `nix flake check` passes.

## Testing
- Dangling-ref sweep: for each `omanix-*` referenced in `modules/` and `pkgs/`, confirm it
  exists in `pkgs/omanix-scripts/src/` or is otherwise packaged. Suggested:
  `comm -23 <(grep -rhoE "omanix-[a-z-]+" modules/ pkgs/ | sort -u) <(ls pkgs/omanix-scripts/src/ | sed 's/\.sh$//' | sort -u)`
  and manually confirm any residue is provided elsewhere.
- `nix flake check`.
- Runtime: confirm the battery keybind (if kept) works and the menu path is intact.

## References
- omanix: `pkgs/omanix-scripts/src/omanix-menu.sh`, `modules/home-manager/ui/walker.nix` (line ~222), `modules/home-manager/desktop/hyprland/bindings.nix` (line ~244)
