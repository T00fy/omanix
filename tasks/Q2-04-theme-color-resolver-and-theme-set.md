# Q2-04: `omanix-theme-color` resolver + `omanix-theme-set` (ephemeral runtime switch)

- **Phase:** 2
- **Status:** todo
- **Depends on:** Q2-03
- **Blocks:** Q2-05, Q2-06, Q4-10
- **Size:** M

## Context
Two CLI scripts underpin runtime theming. `omarchy-theme-color` is the shared `colors.toml`
resolver (semantic palette parser with alias/fallback + mode detection) that every consumer
uses so they agree on the palette. `omarchy-theme-set` performs a theme switch. Under **D2**,
`omanix-theme-set` is an **ephemeral runtime overlay**: it changes the live theme, but a
rebuild/activation (Q2-03) reverts to the declared `omanix.theme`.

## Scope
**In scope:** Port both scripts as `omanix-theme-color` and `omanix-theme-set`, packaged in
`pkgs/omanix-scripts/`. Apply **D1** rename. Wire `omanix-theme-set` to the runtime current-theme
path + IPC apply, and to the built theme set from Q2-03.
**Out of scope:** Image-picker UX (`omanix-theme-switcher`, Q2-05); the code-vs-color security
boundary details (Q2-06, though `theme-set` is where it lives — leave a hook/TODO referencing Q2-06);
palette-only downstream targets like tmux/claude (Q4-10).

## Implementation notes
- Source: `git -C ../omarchy show v4.0.2:bin/omarchy-theme-color` and `:bin/omarchy-theme-set`.
- **`omanix-theme-color`:** pure bash palette resolver. Default colors file path becomes
  `$HOME/.local/state/omanix/current/theme/colors.toml` (D1 rename of the omarchy default).
  Preserve the mode precedence (`mode` key → legacy `theme_type` → `light.mode` file → luminance
  → dark) and the alias/fallback cascade. Modes: `--all`, `--raw`, `<key> [fallback]`, `--file`.
- **`omanix-theme-set`:** switches the live theme. It must:
  - Resolve the requested theme from the built theme set (Q2-03 store path) — themes are
    read-only in the store, so this reads `colors.toml`/`shell.toml` from there rather than
    generating.
  - Materialize them to the runtime current-theme path and apply via `omanix-shell ... applyTheme`
    (Q1-04). Keep the switch **ephemeral**: do not write anything that Q2-03 activation reads.
  - Apply downstream palette-only targets is deferred to Q4-10; `theme-set` may call them if
    present but must not hard-depend on them.
- Package both in `pkgs/omanix-scripts/default.nix` (add to `src/`, wrap with runtime deps: the
  shell IPC CLI, `jq`, coreutils). Follow the existing wrapping pattern.
- Apply the **D1** rename via the vendoring patch phase if these come from vendored source; if
  hand-ported, use omanix names directly and note that in the header.

## Acceptance criteria
- [ ] `omanix-theme-color --all` prints resolved key/value pairs from a `colors.toml`.
- [ ] `omanix-theme-color <key> [fallback]` resolves single keys with the fallback cascade.
- [ ] Mode detection works (explicit `mode`, then luminance fallback).
- [ ] `omanix-theme-set <slug>` switches the live shell to a built theme via IPC.
- [ ] The switch is ephemeral: a subsequent activation/shell restart reverts to declared `omanix.theme`.
- [ ] Both scripts are on `PATH` via `omanix-scripts`.

## Testing
- Unit: `omanix-theme-color --file <a generated colors.toml> --all` returns expected keys; `omanix-theme-color red` returns a hex; unknown key with fallback returns the fallback.
- Runtime (Hyprland session): `omanix-theme-set catppuccin-mocha` visibly re-themes the shell; `omanix-theme-set tokyo-night` switches back; re-activate home-manager and confirm revert to declared theme.
- `nix build .#omanix-scripts` (or the package attr) succeeds; `nix flake check` passes.

## References
- omarchy: `bin/omarchy-theme-color`, `bin/omarchy-theme-set`, `bin/omarchy-shell`
- omanix: `pkgs/omanix-scripts/default.nix`, `pkgs/omanix-scripts/src/`, Q2-03 store layout, Q0-04 state path
