# Q2-03: Build all themes' tomls; apply declared theme on activation via IPC

- **Phase:** 2
- **Status:** done
- **Depends on:** Q2-02, Q1-04
- **Blocks:** Q2-04
- **Size:** M

## Context
This ticket wires the **hybrid theming model (decision D2)**. All themes' `colors.toml` +
`shell.toml` (from Q2-01/Q2-02) are built into the Nix store. The **declared** `omanix.theme`
is the source of truth: on every home-manager activation (and shell restart) it is applied, so
the system always converges to declared config. Runtime switching (Q2-04) is an ephemeral
overlay that this activation reverts.

## Scope
**In scope:** Place every theme's generated tomls into the store; on activation, install the
declared theme's tomls to the shell's runtime location and tell the running shell to apply them
via IPC. Ensure rebuild/restart reverts any runtime override.
**Out of scope:** The runtime `omanix-theme-set` switch script (Q2-04) — but note the shared
runtime path contract here.

## Implementation notes
- **Store layout:** build a derivation (or `pkgs.linkFarm`) mapping each theme slug →
  `{colors.toml, shell.toml}`, e.g. `${omanixThemes}/<slug>/{colors.toml,shell.toml}`. The
  vendored shell (Q1-02) expects theme dirs under `$OMANIX_PATH/themes/<slug>/` — align the
  layout with what the renamed shell's `PluginRegistry`/theme loader reads (verify against the
  vendored `shell/` and `docs/theming.md`).
- **Runtime current-theme path:** omarchy uses `~/.local/state/omarchy/current/theme/colors.toml`
  (+ `shell.toml`); renamed → `~/.local/state/omanix/current/theme/...` (see Q0-04). The declared
  theme's tomls must be materialized there on activation (copy, not symlink into an immutable
  store path the shell may try to overwrite — confirm the shell only reads it).
- **Activation apply:** in the shell HM module (Q1-03) add a home-manager activation step that,
  after seeding the declared theme's tomls, calls the IPC apply (see `omanix-shell ... applyTheme`
  from Q1-04 — omarchy signature is `applyTheme <colorsB64> <shellB64>`). If the shell isn't
  running yet (first activation before session), the on-start path must load the declared theme;
  ensure the shell reads current/theme on launch so a not-yet-running shell still lands correct.
- **Revert semantics:** because activation always re-applies the declared theme, a prior runtime
  `omanix-theme-set` to another theme is overwritten. Document this explicitly (it is the D2
  contract). Do not persist runtime theme choice anywhere that activation reads.
- Add an assertion/eval check that `omanix.theme`'s slug exists in the built theme set.

## Acceptance criteria
- [x] All themes' `colors.toml` + `shell.toml` exist in a store path with a predictable per-slug layout.
- [x] On activation, the declared `omanix.theme`'s tomls are materialized at the runtime current-theme path.
- [x] Activation applies the declared theme to a running shell via IPC (and the shell loads it on cold start).
- [x] A runtime switch to a non-declared theme is reverted by the next activation/shell restart.
- [x] Selecting an unknown `omanix.theme` fails at eval/build with a clear message.

## Implementation notes (done)
- `modules/home-manager/desktop/quickshell.nix` is the only file changed (added `omanixLib` to the
  module args). A `themesStore = pkgs.linkFarm "omanix-themes" …` binding materializes every
  theme's `<slug>/{colors.toml,shell.toml}` into the store from `omanixLib.themesColorsToml` /
  `themesShellToml` (both slug-keyed). Exposed via a new internal readOnly option
  `omanix.quickshell.themesDir` (mirrors `declaredBaseFile`) so Q2-04's `omanix-theme-set` resolves
  switches against the same tree.
- New `home.activation.omanixThemeState` (mirrors `omanixBackgroundState`): seeds
  `~/.local/state/omanix/current/theme` as a **writable symlink into the store**
  (`ln -sfn "${themesStore}/${config.omanix.theme}"`), then best-effort base64-encodes the seeded
  `colors.toml`/`shell.toml` and calls `omanix-shell -q shell applyTheme "$c" "$s"` (guarded, never
  fails activation). The shell reads `current/theme/*` on cold start (`Color.qml` unwatched
  FileViews), so a down shell no-ops; the IPC push re-themes a running one (its FileViews don't
  watch). `shell.qml:879` `applyTheme` takes base64 file *contents*, not a path.
- **Symlink-into-store, not copy** (resolving the ticket's hedge): the shell only *reads*
  `current/theme` — `applyTheme` never writes disk — so a symlink is safe and matches the committed
  `omanixBackgroundState` precedent and Nix idiom.
- **Unknown-theme eval failure** is already provided by `omanix.theme = types.enum availableThemes`
  (`theme/default.nix`), whose enum derives from `omanixLib.themes` — the same source as
  `themesStore`. No extra assertion added.
- **Revert (D2):** activation always re-seeds `current/theme → <declared slug>` and re-applies;
  nothing runtime-written is read by activation, so a prior `omanix-theme-set` is overwritten.
- Verified: `nix flake check` passes; the `linkFarm` derivation builds with
  `tokyo-night/{colors,shell}.toml` + `catppuccin-mocha/{colors,shell}.toml`. Live IPC apply /
  runtime revert are runtime-only to verify in a Hyprland session.

## Testing
- `nix build` the themes store derivation; confirm `<slug>/colors.toml` and `<slug>/shell.toml` exist for every theme.
- Runtime check in a Hyprland session: set `omanix.theme = "catppuccin-mocha"`, activate, confirm the shell renders with that palette; run `omanix-theme-set tokyo-night` (Q2-04), confirm it switches; re-activate, confirm it reverts to catppuccin-mocha.
- `nix flake check` passes.

## References
- omarchy: `bin/omarchy-shell` (IPC `applyTheme`), `docs/theming.md`, `config/omarchy/shell.json`
- omanix: shell HM module (Q1-03), `omanix-shell` CLI (Q1-04), `lib/default.nix`, Q0-04 state layout
