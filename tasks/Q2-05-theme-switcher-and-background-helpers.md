# Q2-05: `omanix-theme-switcher` + background helpers

- **Phase:** 2
- **Status:** todo
- **Depends on:** Q2-04, Q1-08
- **Blocks:** none
- **Size:** M

## Context
User-facing theme and wallpaper switching UX. `omarchy-theme-switcher` is an image-based theme
picker (preview thumbnails via the shell's image-picker/menu). The `omarchy-theme-bg-*` helpers
manage per-theme backgrounds. Omanix today only has `omanix-theme-bg-next` (cycles wallpapers via
swaybg) and a Walker "themes" menu that just tells the user to edit their flake. This ticket
gives omanix a real graphical theme/background switcher backed by the shell — while honoring D2
(theme switch is ephemeral; background choice may persist as runtime state, see notes).

## Scope
**In scope:** Port `omanix-theme-switcher`, `omanix-theme-bg-switcher`, `omanix-theme-bg-cache`,
`omanix-theme-bg-current`. Integrate with the shell's image picker / menu (Q1-08). Package in
`pkgs/omanix-scripts/`.
**Out of scope:** The theme apply mechanism itself (Q2-04); the legacy `omanix-theme-bg-next`
(may be kept, superseded, or reworked — note the decision).

## Implementation notes
- Sources: `git -C ../omarchy show v4.0.2:bin/omarchy-theme-switcher`,
  `:bin/omarchy-theme-bg-switcher`, `:bin/omarchy-theme-bg-cache`, `:bin/omarchy-theme-bg-current`.
- **`omanix-theme-switcher`:** image picker over available themes; on selection calls
  `omanix-theme-set` (Q2-04). Preview caching (omarchy uses a two-tier signature cache + symlinked
  previews); simplify if needed but keep it responsive. Themes come from the built theme set
  (Q2-03) — omanix ships a fixed set, so no git-clone discovery is required (unlike omarchy's
  `omarchy-theme-extras`); document that omanix themes are declared, not user-installed.
- **Backgrounds:** omanix themes already carry `assets.wallpapers` (list) in `lib/themes.nix`.
  - `omanix-theme-bg-switcher` — image picker over the current theme's wallpapers; sets the live
    wallpaper. **Persistence is locked to declared-wins** (background is a separate axis from the
    theme, so it is not auto-covered by D2 — pin it explicitly): the declared
    `wallpaperIndex`/`wallpaperOverride` in `modules/home-manager/theme/default.nix` is the
    **source of truth** and is re-applied on every activation (mirror Q1-03 § *Declarative
    reconcile contract* / D2). A runtime pick is an **ephemeral overlay** written to
    `~/.local/state/omanix/` that is reverted on the next rebuild/activation. Do **not** persist a
    runtime background in a way activation does not override — that would make runtime state the
    source of truth for the wallpaper, the exact anti-declarative pattern D2 avoids.
  - `omanix-theme-bg-cache` — pre-cache background thumbnails for the current theme.
  - `omanix-theme-bg-current` — print the current background's prettified name.
- Reconcile with omanix's existing `omanix-theme-bg-next` and `wallpaperIndex`/`wallpaperOverride`
  options in `modules/home-manager/theme/default.nix` — don't create two competing sources of truth.
- Depends on the shell image-picker/menu being available (Q1-08). Apply **D1** to vendored code.

## Acceptance criteria
- [ ] `omanix-theme-switcher` shows a graphical picker of all declared themes and switches on select (via Q2-04).
- [ ] `omanix-theme-bg-switcher` shows the current theme's wallpapers and sets the selected one live.
- [ ] `omanix-theme-bg-cache` produces cached thumbnails; `omanix-theme-bg-current` prints the current bg name.
- [ ] Declared `omanix.theme` / wallpaper settings win on activation: after a runtime background pick, a rebuild reverts to the declared `wallpaperIndex`/`wallpaperOverride` (runtime pick is an ephemeral overlay in `~/.local/state/omanix/`).
- [ ] No duplicate/conflicting wallpaper source-of-truth with existing options; the declared option is the single source of truth, the runtime pick is only an overlay.

## Testing
- Runtime (Hyprland session): invoke `omanix-theme-switcher`, pick a theme, confirm shell re-themes; invoke `omanix-theme-bg-switcher`, pick a wallpaper, confirm it changes; `omanix-theme-bg-current` prints it.
- `omanix-theme-bg-cache` populates the expected cache dir.
- `nix build` the scripts package; `nix flake check` passes.

## References
- omarchy: `bin/omarchy-theme-switcher`, `bin/omarchy-theme-bg-{switcher,cache,current}`, image-picker plugin
- omanix: `pkgs/omanix-scripts/{default.nix,src/omanix-theme-bg-next.sh}`, `modules/home-manager/theme/default.nix`, `lib/themes.nix`, Q1-08 (menu/image-picker), Q2-04
