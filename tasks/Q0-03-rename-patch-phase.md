# Q0-03: Deterministic `omarchy`→`omanix` rename patch phase (D1)

- **Phase:** 0
- **Status:** todo
- **Depends on:** Q0-01, Q0-05
- **Blocks:** Q1-02
- **Size:** M

## Context
Decision **D1**: everything vendored from omarchy is rebranded to the omanix namespace, but the
rename must be a **deterministic, reusable build step** applied to pinned upstream source — never
a hand-edited fork. This keeps upstream re-syncs to "bump the pin + rebuild + review the diff."
This ticket builds that reusable rename step so Q1-02 (and later script-port tickets) can call
it. The vendored shell hardcodes `omarchy-*` command names, `omarchy.*` plugin IPC ids, and
`$OMARCHY_PATH`; all must become `omanix`.

## Scope
**In scope:** a reusable Nix function/phase that takes an upstream source tree and returns a
renamed tree; the exact substitution rules; a review workflow for the diff on each bump.
**Out of scope:** the `omanix-shell` derivation itself (Q1-02); renaming things omanix already
authored (they're already `omanix-*`).

## Implementation notes
- Implement as a small Nix helper, e.g. `lib/vendor-rename.nix` exposing
  `renameOmarchy = src: pkgs.runCommand "omanix-renamed-src" {...} ''...''` that copies `src`
  and runs the substitutions, OR a `postPatch`/`postUnpack` snippet reused across derivations.
  Prefer a single function so the rules live in one place.
- **Substitution rules (ordered, apply the most specific first):**
  1. `OMARCHY_PATH` → `OMANIX_PATH` (env var).
  2. `omarchy.` → `omanix.` — plugin IPC ids and QML namespaces (e.g. `omarchy.menu`,
     `omarchy.bar`, `module qs.Commons` unaffected; only the `omarchy.` prefix). **Caution:**
     this also matches things like `omarchy.org` domains — scope to avoid URLs (see gotchas).
  3. `omarchy-` → `omanix-` (command names, e.g. `omarchy-shell` → `omanix-shell`).
  4. `omarchy` → `omanix` (bare word: paths like `~/.config/omarchy`, `~/.local/state/omarchy`,
     `/usr/share/omarchy` → but the last is irrelevant on Nix; and reserved-namespace checks).
- **Gotchas / false positives to guard against:**
  - **URLs**: `omarchy.org`, `learn.omacom.io`, `github.com/omacom/omarchy`, package repo URLs.
    A blanket `omarchy`→`omanix` would corrupt these. Either (a) exclude URL-bearing files
    (docs, help text) from the sweep, or (b) protect URL patterns first (rewrite
    `omarchy.org`→sentinel, sweep, restore) — document whichever is chosen.
  - **User-facing strings**: window titles, notification text, help output. Renaming these is
    desired (branding) but verify none feed logic (e.g. window `app-id` used in Hyprland rules
    — those SHOULD rename consistently on both sides).
  - **Reserved-namespace validation**: `bin/omarchy-plugin-validate` and
    `shell/services/PluginRegistry.qml` reject the `omarchy.*` id namespace for third-party
    plugins. After rename these must read `omanix.*` — ensure the sweep covers the validation
    literals too (it will, via rule 2).
  - Binary/asset files (SVG, TTF, PNG, `emojis.json`): do NOT text-substitute binaries. Restrict
    the sweep to text extensions (`.qml`, `.js`, `.sh`, `.json`, `.toml`, `.md`, `.conf`, `.lua`).
- **This sweep is cosmetic (names only) — it does NOT fix behavioral Arch-coupling.** Per Q0-05,
  two things inside the shell tree are landmines the rename cannot repair and must be handled
  elsewhere: the embedded `pacman -Qq/-Qi/-Q` guard batch in `shell/plugins/menu/MenuModel.js`
  (→ Q1-08) and `pkexec tailscale set --operator` in the tailscale panel (→ Q4-07). Renaming
  `omarchy-`→`omanix-` on a command that has no omanix implementer just relocates the runtime
  failure; Q0-05's disposition table is the authority on which commands must exist vs. which
  plugins are disabled.
- Use `find ... -type f` filtered by extension + `sed -i` / `substituteInPlace`. Keep the rule
  list as a bash array or Nix list so it's auditable.
- **Diff review workflow (document in the ticket output):** provide a command to diff the
  renamed tree against the raw upstream tree so a human can eyeball the sweep after each pin
  bump, e.g. build both and `diff -r`. Note expected categories of change.

## Acceptance criteria
- [ ] A single reusable helper performs the rename (one place holds the rules).
- [ ] All four substitution rules implemented, applied specific-first.
- [ ] URLs / external references are demonstrably NOT corrupted (spot-checked on the real shell tree).
- [ ] Binary/asset files are left untouched.
- [ ] Applied to the omarchy `shell/` tree: no residual `omarchy` in code paths, no broken `omanix.omanix`, plugin ids read `omanix.*`, `OMANIX_PATH` used throughout.
- [ ] A documented command produces a reviewable diff (renamed vs raw upstream) for future bumps.

## Testing
```bash
cd /home/toofy/projects/omanix
# Build the renamed tree (helper exposed for testing, or via a scratch derivation):
nix build .#omanix-shell    # once Q1-02 exists it consumes this; before that, a test attr
# Assertions on the built output ($out):
! grep -rIl 'omarchy-' $out/shell        # no omarchy- command refs
! grep -rIl 'OMARCHY_PATH' $out/shell    # no old env var
grep -rIl 'omanix\.menu' $out/shell      # plugin ids renamed
# URL integrity spot check (must still contain upstream URLs unbroken if any retained):
grep -rI 'omarchy.org\|omacom' $out/shell || echo "no urls retained (acceptable)"
```
Manual: run the documented raw-vs-renamed diff and confirm only intended changes.

## References
- omarchy: `shell/` tree; `bin/omarchy-shell`; `bin/omarchy-plugin-validate`; `shell/services/PluginRegistry.qml`
- omanix: new `lib/vendor-rename.nix` (or equivalent); consumed by `pkgs/omanix-shell/` (Q1-02)
