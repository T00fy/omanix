# Q2-01: Emit `colors.toml` per theme from the existing palette

- **Phase:** 2
- **Status:** todo
- **Depends on:** Q1-02
- **Blocks:** Q2-02, Q2-04, Q4-09
- **Size:** M

## Context
The Quickshell shell (vendored in Q1-02) reads a theme's palette from a `colors.toml` file
(at runtime: `~/.local/state/omanix/current/theme/colors.toml`; per-theme source lives in the
shell's theme dirs). Omanix currently has no `colors.toml` — its palette lives as Nix data in
`lib/themes.nix` (schema `lib/theme-schema.nix`). This ticket generates an omarchy-compatible
`colors.toml` from that existing Nix palette, for **every** theme, so the shell has colors to
consume. This is an **extension** of the current theme data, not a new engine.

Omarchy reference `colors.toml` (tokyo-night) uses these keys:
```
mode = "dark"
accent, selection, muted
background, dark_background, darker_background, lighter_background
foreground, dark_foreground, light_foreground, bright_foreground
red, yellow, orange, green, cyan, blue, magenta, brown
bright_red, bright_yellow, bright_green, bright_cyan, bright_blue, bright_magenta
```

Omanix palette (`lib/themes.nix`) provides: `background, foreground, accent, cursor,
selection_background, selection_foreground, color0..color15`.

## Scope
**In scope:** A Nix function that renders a `colors.toml` string for one theme's palette, and
wiring so all themes produce a `colors.toml`. Key mapping (below). Adding a `mode` value.
**Out of scope:** `shell.toml` (Q2-02), placing/activating the toml at runtime (Q2-03),
runtime switching scripts (Q2-04).

## Implementation notes
- Add a renderer, e.g. `lib/theme-toml.nix` (`{ palette, mode }: -> string`), aggregated in
  `lib/default.nix` (`omanixLib`).
- **Key mapping (ANSI ↔ semantic convention used by `omarchy-theme-color`):**
  - `background` ← `colors.background`; `foreground` ← `colors.foreground`; `accent` ← `colors.accent`.
  - `selection` ← `colors.selection_background`.
  - Named colors from the ANSI palette: `red`←color1, `green`←color2, `yellow`←color3,
    `blue`←color4, `magenta`←color5, `cyan`←color6.
  - Bright variants: `bright_red`←color9, `bright_green`←color10, `bright_yellow`←color11,
    `bright_blue`←color12, `bright_magenta`←color13, `bright_cyan`←color14.
  - `muted`←color8 (dim/comment). `orange`/`brown` have no direct omanix source — **derive** by
    hex-mixing (reuse/extend `lib/color-utils.nix`, add a `mix` if absent) or fall back to a
    sensible named color; document the choice. `omarchy-theme-color` itself derives missing
    shades, so approximate derivation is acceptable.
  - Background/foreground shades (`dark_background`, `darker_background`, `lighter_background`,
    `dark_foreground`, `light_foreground`, `bright_foreground`): derive by mixing background/
    foreground toward black/white (extend `color-utils.nix`). These are what the shell uses for
    surface depth.
- **`mode`:** add `meta.mode` (`"dark"|"light"`) to `lib/theme-schema.nix` (both existing themes
  are dark), OR derive from background luminance via a `color-utils.nix` helper. Prefer an
  explicit schema field for reproducibility; default `"dark"`.
- Consider consolidating the mapping so a new theme only needs the existing palette keys +
  `meta.mode`; missing keys derive automatically.
- **D1** applies to any vendored strings, but this file is omanix-authored so it uses omanix
  paths directly.

## Acceptance criteria
- [ ] A pure Nix function renders a valid omarchy-format `colors.toml` from an omanix palette.
- [ ] All keys present in the omarchy reference `colors.toml` are emitted with plausible values.
- [ ] Both shipped themes (`tokyo-night`, `catppuccin-mocha`) render without eval errors.
- [ ] `mode` is present and correct for each theme.
- [ ] No new mandatory data required per theme beyond the current palette + `meta.mode`.

## Testing
- `nix eval` the renderer for both themes; assert output is non-empty and contains `background`,
  `red`, `bright_magenta`, `mode`.
- Diff generated tokyo-night `colors.toml` against `git -C ../omarchy show v4.0.2:themes/tokyo-night/colors.toml`; values need not be identical, but every key must be present.
- `nix flake check` passes; options doc still builds if the schema gained a field.

## References
- omarchy: `themes/tokyo-night/colors.toml`, `bin/omarchy-theme-color` (resolution/alias cascade)
- omanix: `lib/themes.nix`, `lib/theme-schema.nix`, `lib/color-utils.nix`, `lib/default.nix`, `modules/home-manager/theme/default.nix`
