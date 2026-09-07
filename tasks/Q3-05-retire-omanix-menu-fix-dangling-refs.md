# Q3-05: Retire/repurpose `omanix-menu.sh`; fix dangling script refs

- **Phase:** 3
- **Status:** done
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

## Resolution
The ticket's premise was largely overtaken by later Phase-1/3 work:
- **`omanix-menu.sh`** was already retired-into-a-shim by **Q1-08** — it is no longer the
  bash/Walker control panel but a thin `omanix-shell shell toggle|show|hide omanix.menu` IPC
  wrapper. The two helpers `omanix-menu-{keybindings,style}.sh` were rewired off Walker onto the
  `omanix-menu-dmenu` shim by **Q3-03**. Decision: **keep all three (repurposed); no fallback
  bash surface.**
- **`omanix-restart-walker`** died with `ui/walker.nix` in **Q3-03**; repo-wide grep finds zero
  references.
- **`omanix-battery-remaining`** was the sole live dangler (`bindings.nix:244` "Show Battery").
  **Dropped the keybind** — battery % is shown by the bar's `omanix.power` widget (Q1-13), so the
  notify is redundant under the shell. The sibling `SUPER+CTRL+ALT+T` "Show Time" (self-contained
  `date`) is kept.

The broader dangling-ref sweep was audited: all remaining `omanix-*` residue is benign —
state-file names (`omanix-idle-inhibited`, `omanix-screenrecording`), PAM service names
(`omanix-lock-password`/`-fingerprint`), separately-packaged commands (`omanix-screensaver`,
`omanix-toggle-sunshine`), guarded runtime probes (`omanix-installed-service-*`), the deferred
`omanix-scale.sh` subsystem's internal subcommands, and intentionally-optional future-ticket
best-effort calls (`omanix-theme-set-{tmux,claude,pi,browser}` → Q4-10, `omanix-plugin-catalog`
→ Q4-01).

## Acceptance criteria
- [x] Decision on `omanix-menu.sh` (retire or fallback) is implemented and noted in the commit.
- [x] No reference anywhere to `omanix-restart-walker` or any removed walker command.
- [x] `omanix-battery-remaining` reference is resolved (removed or backed by a real command).
- [x] `grep` across `modules/` + `pkgs/` finds no invocation of a script absent from
      `pkgs/omanix-scripts/src/` (and not provided elsewhere).
- [x] `nix flake check` passes.

## Testing
- Dangling-ref sweep: for each `omanix-*` referenced in `modules/` and `pkgs/`, confirm it
  exists in `pkgs/omanix-scripts/src/` or is otherwise packaged. Suggested:
  `comm -23 <(grep -rhoE "omanix-[a-z-]+" modules/ pkgs/ | sort -u) <(ls pkgs/omanix-scripts/src/ | sed 's/\.sh$//' | sort -u)`
  and manually confirm any residue is provided elsewhere.
- `nix flake check`.
- Runtime: confirm the battery keybind (if kept) works and the menu path is intact.

## References
- omanix: `pkgs/omanix-scripts/src/omanix-menu.sh`, `modules/home-manager/ui/walker.nix` (line ~222), `modules/home-manager/desktop/hyprland/bindings.nix` (line ~244)
