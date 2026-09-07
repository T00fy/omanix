# Q3-04: Clipboard/menu helper CLIs (`omanix-menu-*`, `omanix-clipboard-*`)

- **Phase:** 3
- **Status:** done
- **Depends on:** Q1-09
- **Blocks:** none
- **Size:** M

## Context
The shell exposes several menu/clipboard surfaces driven by small CLI helpers. Q1-09 brings
up the clipboard + emoji plugins and their primary CLIs; this ticket ports the remaining
helper commands that back menu entries and clipboard actions, wiring them to the shell.

Target commands (omarchy names → rename per D1): `omarchy-clipboard-{open,paste-file,
paste-text}`, `omarchy-menu-{clipboard,emoji,emoji-insert,images,timezone}`.

## Scope
**In scope:** port the listed helpers into `pkgs/omanix-scripts/src/` (renamed `omanix-*`),
add them to `pkgs/omanix-scripts/default.nix` with correct runtime deps and wrapper env,
wire them to the shell IPC and plugins.
**Out of scope:** the plugin/menu system CLI (`omanix-plugin-*`, `omanix-menu-plugin` — that
is Q4-01); the primary clipboard/emoji CLIs already covered by Q1-09.

## Implementation notes
- Study omarchy sources: `bin/omarchy-clipboard-*`, `bin/omarchy-menu-{clipboard,emoji,
  emoji-insert,images,timezone}`. These are thin bash wrappers over the shell IPC + jq +
  wl-clipboard/cliphist.
- omanix packages scripts via `pkgs/omanix-scripts/default.nix` (stdenv + `wrapProgram` with
  injected deps and `--set` env). Add each new script there with its deps (jq, wl-clipboard,
  cliphist, etc.) and any needed env (menu dimensions, theme JSON) matching existing patterns.
- D1: rename everything to `omanix-*`; IPC targets are `omanix.*`.
- Gotcha: clipboard paste helpers handle large/UTF-16 pastes in omarchy — preserve that
  handling. `emoji-insert` types into the focused window (wtype/ydotool) — bring its dep.

## Resolution (reconciliation — no new scripts)
Every live helper this ticket names was already delivered by earlier work, so Q3-04 adds no
new scripts:
- `omanix-clipboard-{open,paste-text,paste-file}`, `omanix-menu-{emoji,emoji-insert}` — Q1-09.
- `omanix-menu-images` — Q2-05.

The two absent names resolve out rather than being ported:
- `omanix-menu-clipboard` — **skipped**: zero callers anywhere (menu jsonc, QML, keybinds). The
  clipboard picker is already opened by `omanix-clipboard-open`
  (`omanix-shell shell toggle omanix.clipboard`, SUPER+CTRL+V). A separate helper would be dead
  weight.
- `omanix-menu-timezone` — **cut**: ratified in Q0-05 (declared-config pickers). On NixOS the
  timezone is `time.timeZone` (D4). Its only reference was the clock middle-click
  `bar.run("omanix-menu-timezone")` at `plugins/panels/clock/BarWidget.qml:155`; that handler
  was removed (vendored edit logged in `vendor/PROVENANCE.md`), so middle-click now falls
  through to `togglePanel()`.

`omanix-menu-plugin` was never in this ticket's scope — it belongs to Q4-01.

## Acceptance criteria
- [x] Each listed helper exists as `omanix-*` in `pkgs/omanix-scripts/src/` and is packaged
      (via Q1-09 / Q2-05); the two remaining names are intentionally skipped/cut (see Resolution).
- [x] Each shipped helper drives the shell (clipboard picker opens, emoji inserts, images menu
      summons); timezone menu is cut, its dangling caller removed.
- [x] Runtime deps declared; no unbound `PATH` lookups at runtime (unchanged from Q1-09/Q2-05).
- [x] `nix flake check` and `nix build .#omanix-scripts` pass.

## Testing
- `nix build` the scripts package; run each helper from a session with the shell up and
  confirm the expected surface appears / action occurs.
- `omanix-clipboard-paste-text` and `-paste-file` round-trip a clipboard entry.
- `nix flake check`.

## References
- omarchy: `bin/omarchy-clipboard-*`, `bin/omarchy-menu-{clipboard,emoji,emoji-insert,images,timezone}`
- omanix: `pkgs/omanix-scripts/{default.nix,src/}`
