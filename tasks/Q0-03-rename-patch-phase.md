# Q0-03: `omarchy`→`omanix` rename ruleset (applied at vendor time)

- **Phase:** 0
- **Status:** todo
- **Depends on:** Q0-01, Q0-05
- **Blocks:** Q1-02
- **Size:** M

## Context
Decision **D1**: everything vendored from omarchy is rebranded to the omanix namespace. Because
omanix now takes a **committed in-repo snapshot** (Q0-01) rather than fetching upstream at build
time, the rename is applied **once, at vendor time**, and the renamed result is committed. It is
**not** a build-time derivation phase — `nix build` consumes the already-renamed `vendor/omanix-shell/`
tree as-is. This ticket defines the substitution ruleset and packages it as the rename step of the
re-vendor helper (`scripts/vendor-omarchy.sh`, Q0-01), so that a future re-vendor of a newer omarchy
re-applies the exact same rules deterministically and produces a reviewable diff.

The vendored shell hardcodes `omarchy-*` command names, `omarchy.*` plugin IPC ids, and
`$OMARCHY_PATH`; all must become `omanix`.

## Scope
**In scope:** the exact substitution rules; a **re-runnable rename step** (a shell function/script
invoked by `scripts/vendor-omarchy.sh`) that transforms a raw upstream tree into a renamed tree;
the diff-review workflow for each re-vendor.
**Out of scope:** the `omanix-shell` package (Q1-02, which just installs the committed renamed
tree); the vendor location and provenance (Q0-01); renaming omanix-authored code (already `omanix-*`).

## Implementation notes
- **Not a Nix build phase.** Earlier this was planned as a `runCommand`/`substituteInPlace` step
  inside the derivation. Under the snapshot model the rename runs at vendor time on the developer's
  machine and its output is committed. Implement it as a shell step of `scripts/vendor-omarchy.sh`
  (or a `scripts/rename-omarchy.sh` it calls) so the rules live in one auditable place. No Nix
  helper (`lib/vendor-rename.nix`) is needed; if one was stubbed, drop it.
- **Substitution rules (ordered, apply the most specific first):**
  1. `OMARCHY_PATH` → `OMANIX_PATH` (env var).
  2. `omarchy.` → `omanix.` — plugin IPC ids and QML namespaces (e.g. `omarchy.menu`,
     `omarchy.bar`). **Caution:** this also matches things like `omarchy.org` domains — scope to
     avoid URLs (see gotchas).
  3. `omarchy-` → `omanix-` (command names, e.g. `omarchy-shell` → `omanix-shell`).
  4. `omarchy` → `omanix` (bare word: paths like `~/.config/omarchy`, `~/.local/state/omarchy`).
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
  - The sweep's `sed` must be UTF-8 safe (Nerd Font glyphs are embedded raw in widget QML); scope
    patterns to ASCII so multibyte codepoints pass through untouched.
- **This sweep is cosmetic (names only) — it does NOT fix behavioral Arch-coupling.** Per Q0-05,
  two things inside the shell tree are landmines the rename cannot repair and must be handled
  elsewhere: the embedded `pacman -Qq/-Qi/-Q` guard batch in `shell/plugins/menu/MenuModel.js`
  (→ Q1-08) and `pkexec tailscale set --operator` in the tailscale panel (→ Q4-07). Renaming
  `omarchy-`→`omanix-` on a command that has no omanix implementer just relocates the runtime
  failure; Q0-05's disposition table is the authority on which commands must exist vs. which
  plugins are disabled. Because the vendored tree is **committed and editable** (Q0-01), these
  landmines can also simply be hand-fixed in `vendor/omanix-shell/` after the sweep — record any
  such local edit per Q0-01's local-edit policy.
- Use `find ... -type f` filtered by extension + `sed -i`. Keep the rule list as a bash array so
  it's auditable and identical across re-vendors.
- **Diff review workflow:** since the renamed tree is committed, the reviewable diff on a re-vendor
  is just the working-tree diff `scripts/vendor-omarchy.sh` produces against the committed
  `vendor/omanix-shell/` (`git diff vendor/`). Document the expected categories of change so a
  human can eyeball a future bump.

## Acceptance criteria
- [ ] The rename ruleset lives in one place (a shell step of the Q0-01 re-vendor helper), not a Nix build phase.
- [ ] All four substitution rules implemented, applied specific-first.
- [ ] URLs / external references are demonstrably NOT corrupted (spot-checked on the real shell tree).
- [ ] Binary/asset files are left untouched; glyph encoding preserved (UTF-8-safe sed).
- [ ] Applied to the omarchy `shell/` tree and committed to `vendor/omanix-shell/`: no residual `omarchy` in code paths, no broken `omanix.omanix`, plugin ids read `omanix.*`, `OMANIX_PATH` used throughout.
- [ ] Re-running the rename step is deterministic (same input rev → same committed tree), producing a reviewable `git diff` on a bump.

## Testing
```bash
cd /home/toofy/projects/omanix
# The committed renamed tree is the artifact — assert directly on it:
! grep -rIl 'omarchy-' vendor/omanix-shell       # no omarchy- command refs
! grep -rIl 'OMARCHY_PATH' vendor/omanix-shell   # no old env var
grep -rIl 'omanix\.menu' vendor/omanix-shell     # plugin ids renamed
grep -rI 'omarchy.org\|omacom' vendor/omanix-shell || echo "no urls retained (acceptable)"
# Determinism: re-run the vendor helper at the recorded rev → no diff:
scripts/vendor-omarchy.sh <recorded-rev> && git diff --stat vendor/omanix-shell
```
Manual: review the `git diff vendor/` a re-vendor produces and confirm only intended changes.

## References
- omarchy: `shell/` tree; `bin/omarchy-shell`; `bin/omarchy-plugin-validate`; `shell/services/PluginRegistry.qml`
- omanix: `scripts/vendor-omarchy.sh` (Q0-01) rename step; committed output `vendor/omanix-shell/`; consumed by `pkgs/omanix-shell/` (Q1-02)
