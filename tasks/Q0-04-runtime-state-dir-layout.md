# Q0-04: Runtime state dir layout (`~/.local/state/omanix`)

- **Phase:** 0
- **Status:** todo
- **Depends on:** none
- **Blocks:** Q2-03, Q2-04, Q5-03 (soft — these read/write state)
- **Size:** S

## Context
The Quickshell shell and several ported features keep **mutable per-user runtime state** that
is NOT declarative: the currently-active (possibly runtime-switched) theme, toggle flags
(idle/DND/crash-capture/stay-awake), and agent usage records. Upstream omarchy stores these
under `~/.local/state/omarchy/`. Per **D1** omanix uses `~/.local/state/omanix/`. This ticket
establishes the canonical layout and the ownership rule (declarative config seeds/overrides it;
runtime writes are ephemeral overlays per **D2**) so later tickets write to consistent paths.

## Scope
**In scope:** define the directory tree and each file's purpose/owner; document the
declarative-vs-runtime rule; ensure the dir is created (not managed as store symlinks).
**Out of scope:** the features that read/write these files (their own tickets); migrating any
existing omanix state.

## Implementation notes
- Canonical root: `${XDG_STATE_HOME:-~/.local/state}/omanix/`. Enumerate (from the omarchy
  reports; adjust names as the ported code lands):
  - `current/` — active theme + background pointers (omarchy moved `current` from `~/.config`
    to `~/.local/state`). Runtime theme switches (Q2-04) write here; the declared `omanix.theme`
    (Q2-03) rewrites it on activation.
  - `toggles/` — flag files: `idle-*`, `dnd`, `crash-capture-off`, `stay-awake`, etc. Presence
    = state. Toggle scripts create/remove them.
  - `agents/usage/<agent>.json` — usage collector output (Q5-02).
  - `done/` — one-shot markers (only if any ported feature needs them; most provisioning
    markers are out of scope).
- **Ownership rule (write this into the ticket + reference D2):** declarative config is the
  source of truth and is (re)applied on every rebuild/activation; runtime tools may overlay
  ephemeral changes here, which revert on the next rebuild/shell restart. State files must
  therefore be **created/seeded by activation (copy), never symlinked into the immutable Nix
  store** (they must be writable). See risk R3 in `../PORTING-QUATTRO.md`.
- Provide a tiny shared helper (bash) or documented convention for resolving the state root
  (`omanix_state_dir()` honoring `XDG_STATE_HOME`) so ported scripts agree. Optionally add a
  `home.activation` step or `xdg` tmpfiles to `mkdir -p` the base dirs.
- Do not over-engineer: this ticket is the *contract*. Only create dirs that a landed feature
  needs; extend the enumerated list as tickets add state.

## Acceptance criteria
- [ ] A documented state-dir layout exists (in this ticket and referenced from code comments).
- [ ] The base directory is ensured writable per-user (activation `mkdir`/tmpfiles, not a store symlink).
- [ ] A shared resolver/convention for the state root honoring `XDG_STATE_HOME` is defined.
- [ ] The declarative-vs-runtime ownership rule is written down and points at D2.
- [ ] `nix flake check` passes.

## Testing
```bash
cd /home/toofy/projects/omanix
nix flake check
```
Runtime (once wired): after activation, `test -d ~/.local/state/omanix` and the dir is
user-writable (`touch ~/.local/state/omanix/toggles/probe && rm` succeeds).

## References
- omarchy: `~/.local/state/omarchy/` usage across `bin/omarchy-toggle-*`, theme `current`, `bin/omarchy-agent-usage-update`
- omanix: activation logic (see `modules/home-manager/theme/default.nix` for current theme handling); `../PORTING-QUATTRO.md` R3 & D2
