# Q2-02: Port `shell.toml.tpl` (13 sections) → Nix generation

- **Phase:** 2
- **Status:** done
- **Depends on:** Q2-01
- **Blocks:** Q2-03
- **Size:** L

## Context
Beyond `colors.toml` (palette), the Quickshell shell reads a `shell.toml` that defines UI
surface tokens (sizes, alphas, borders, typographic scale). Omarchy generates it from
`default/themed/shell.toml.tpl` by substituting palette values. This ticket ports that template
to a Nix generator so omanix emits a `shell.toml` per theme.

The template has **13 sections**: `[bar] [hyprland] [controls] [spacing] [font] [popups]
[tooltip] [notifications] [launcher] [menu] [polkit] [lock] [image-picker]`.

## Scope
**In scope:** A Nix generator producing a valid `shell.toml` from a resolved palette; port the
template's substitution helpers; emit for all themes.
**Out of scope:** Runtime placement/activation (Q2-03); theme-switching scripts (Q2-04).

## Implementation notes
- Add e.g. `lib/shell-toml.nix` (`{ palette }: -> string`), aggregated in `omanixLib`. Depends on
  the resolved palette from Q2-01 (so `red`, `accent`, `background`, etc. are available).
- **Template helper functions to reproduce in Nix** (they appear inside `{{ }}` in the tpl):
  - `{{ mix <a> <b> <pct> }}` — hex-mix two palette colors (used e.g.
    `placeholder = "{{ mix foreground background 34% }}"`). Implement in `lib/color-utils.nix`.
  - `{{ shell_gradient hyprland_active_border accent }}` / `... foreground` — builds the
    Hyprland-style active-border gradient tokens for `[hyprland]`. Reproduce the gradient string
    the shell expects (study how omarchy computes `hyprland_active_border`; it derives from the
    Hyprland border gradient — align with omanix `desktop/hyprland/visuals.nix` border colors).
  - Plain `{{ background }}`, `{{ foreground }}`, `{{ accent }}`, `{{ red }}` — direct palette
    substitution.
- **Most non-color keys are constants** (sizes, alphas, `scale`, `base-size`, booleans). Emit
  them verbatim from the tpl; only color-valued keys need substitution. Keep the commented-out
  override lines or drop them — document the choice (keeping them aids user tweaking).
- Note the literal token references like `border = "hyprland.active-border"` are **not**
  substituted — they are cross-section references the shell resolves. Emit as-is.
- Fetch the full template: `git -C ../omarchy show v4.0.2:default/themed/shell.toml.tpl`.
- **D1** rename does not apply to this omanix-authored generator, but the *values* must match
  what the (renamed) shell expects — keys are unchanged by the rename.

## Acceptance criteria
- [x] `shell.toml` generator emits all 13 sections with correct keys.
- [x] `mix` and `shell_gradient` helpers implemented and produce valid color/gradient strings.
- [x] Generated `shell.toml` parses as valid TOML.
- [x] Both shipped themes generate without eval errors.
- [x] Cross-section references (`"hyprland.active-border"`, etc.) preserved literally.

## Implementation notes (done)
- Generator: `lib/shell-toml.nix` (`{ lib }: { colors, hyprlandActiveBorder ? null }: -> string`),
  exposed as `omanixLib.renderShellToml`; `omanixLib.themesShellToml` maps it over all themes
  (Q2-03 consumes it, alongside `themesColorsToml`).
- Only 4 palette-derived color keys are needed (`background`, `foreground`, `accent`, `red←color1`),
  plus one `mix foreground background 34%` (`[lock] placeholder`, reuses `color-utils.mix`) and the
  two `[hyprland]` border tokens.
- `shell_gradient` ported as `color-utils.shellGradient` (`{ spec ? null, fallback }`): shipped
  themes pass `spec = null` → emit the solid fallback (`accent` / `foreground`), matching omanix's
  solid `rgb(accent)` Hyprland border (`visuals.nix`). `hyprland_active_border` is an optional theme
  key upstream; neither omanix theme defines a gradient, so no gradient string is emitted.
- Output is lean per decision: verbatim key/value coverage, comments stripped (kept in the generator
  source). Cross-section refs (`"hyprland.active-border"`, `-foreground`) emitted as literals.
- Verified: both themes eval, `taplo lint` clean, all 13 headers present, zero stray `{{`, every
  upstream non-comment key present, `nix flake check` passes.

## Testing
- `nix eval` the generator for both themes; pipe output through a TOML validator
  (`nix run nixpkgs#taplo -- lint` or a Python `tomllib.loads` check) — must parse.
- Assert all 13 section headers are present.
- Compare section/key coverage against the upstream tpl (every non-comment key present).
- `nix flake check` passes.

## References
- omarchy: `default/themed/shell.toml.tpl`, `bin/omarchy-theme-set-templates` (how helpers are applied), `docs/theming.md`
- omanix: `lib/color-utils.nix`, `lib/default.nix`, `modules/home-manager/desktop/hyprland/visuals.nix` (border gradient source)
