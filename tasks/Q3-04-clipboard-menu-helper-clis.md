# Q3-04: Clipboard/menu helper CLIs (`omanix-menu-*`, `omanix-clipboard-*`)

- **Phase:** 3
- **Status:** todo
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

## Acceptance criteria
- [ ] Each listed helper exists as `omanix-*` in `pkgs/omanix-scripts/src/` and is packaged.
- [ ] Each drives the shell (clipboard picker opens, emoji inserts, images/timezone menus summon).
- [ ] Runtime deps declared; no unbound `PATH` lookups at runtime.
- [ ] `nix flake check` and `nix build .#omanix-scripts` pass.

## Testing
- `nix build` the scripts package; run each helper from a session with the shell up and
  confirm the expected surface appears / action occurs.
- `omanix-clipboard-paste-text` and `-paste-file` round-trip a clipboard entry.
- `nix flake check`.

## References
- omarchy: `bin/omarchy-clipboard-*`, `bin/omarchy-menu-{clipboard,emoji,emoji-insert,images,timezone}`
- omanix: `pkgs/omanix-scripts/{default.nix,src/}`
