# Q4-10: Palette-only theme targets (tmux/claude/pi/browser/osc)

- **Phase:** 4
- **Status:** done
- **Depends on:** Q2-04
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 pushes the active palette into several non-shell targets. These need no
Quickshell — only the resolved palette (Q2-04's `omanix-theme-color` resolver). This ticket
ports the palette-only theme targets.

omarchy source:
- `bin/omarchy-theme-set-tmux` (~120 lines) — pushes palette into tmux via `set-environment`,
  sets `COLORFGBG`, window/cursor styles, emits OSC to each pane tty, SIGWINCHes panes. Also
  applied to herdr (tmux's sibling; see Q4-11).
- `bin/omarchy-theme-set-claude` — writes generated `claude.json` to
  `~/.claude/themes/omarchy.json` (hot-reloaded by Claude Code); `--activate` sets
  `settings.json` `theme = "custom:omarchy"`.
- `bin/omarchy-theme-set-pi` — same pattern for the Pi agent:
  `~/.pi/agent/themes/omarchy-system.json` + settings theme `omarchy-system`.
- `bin/omarchy-theme-set-browser-policy` (~123 lines) — writes
  `{"BrowserThemeColor","BrowserColorScheme"}` into Chromium/Chrome/Edge/Brave managed-policy
  dirs (`/etc/<browser>/policies/managed/color.json`); privileged via a dedicated passwordless
  sudoers rule (`etc/sudoers.d/omarchy-theme-browser`); accepts only 6 lowercase hex digits.
- `bin/omarchy-theme-osc` — prints OSC escape sequences (10/11/12/17/19 + `4;N`) from a
  `colors.toml` for live terminal retinting.

## Scope
**In scope:** ported `omanix-theme-set-{tmux,claude,pi}`, `omanix-theme-osc`, and a
declarative reframing of `omanix-theme-set-browser-policy`. Wire tmux and claude/pi targets
to update on theme change alongside the hybrid switch flow from Q2-04.
**Out of scope:** the Quickshell `shell.toml` targets (Q2-02); herdr's own theming (Q4-11,
which reuses the tmux approach); vscode theme (can be a follow-up).

## Implementation notes
- All targets consume the resolved palette from **Q2-04's `omanix-theme-color`** — do not
  re-parse `colors.toml` ad hoc; call the resolver.
- **D1:** rename `omarchy-*` → `omanix-*`; file targets become `~/.claude/themes/omanix.json`
  (`custom:omanix`), `~/.pi/agent/themes/omanix-system.json`. Relate to
  `modules/home-manager/apps/ai.nix` — claudeCode already writes `~/.claude.json`; the theme
  target should coexist (write the theme file + optionally set `theme` in settings).
- **tmux:** omanix has `modules/home-manager/apps/tmux.nix`. The `omanix-theme-set-tmux`
  script updates a running tmux at runtime (ephemeral). For the declarative baseline, generate
  the tmux theme from the palette in `tmux.nix` so a rebuild sets the declared theme; the
  script handles live switching. Mirror this coexistence for herdr in Q4-11.
- **browser-policy — reframe declaratively:** on Nix, managed-policy files under `/etc/<browser>/policies/managed/`
  should be written via `environment.etc."chromium/policies/managed/color.json"` (and
  brave/edge/chrome equivalents) generated from the palette, **not** a privileged runtime
  script + sudoers rule. Drop the `sudoers.d/omarchy-theme-browser` mechanism entirely — the
  Nix store + `environment.etc` replaces it. Provide an `omanix.theme.browserPolicy.enable`
  option. (For the *ephemeral* runtime switch, note that `/etc` is read-only under Nix, so
  browser color only tracks the declared theme — acceptable; document it.)
- **claude/pi/tmux/osc** are user-writable (`$HOME`, tty) so they support the ephemeral
  runtime switch cleanly.

## Acceptance criteria
- [ ] `omanix-theme-set-tmux` retints a running tmux to the current palette (colors, cursor,
      COLORFGBG); the declared theme is applied by `tmux.nix` on rebuild.
- [ ] `omanix-theme-set-claude` writes `~/.claude/themes/omanix.json` from the palette and can
      activate it; works with `apps/ai.nix` claudeCode enabled.
- [ ] `omanix-theme-set-pi` writes `~/.pi/agent/themes/omanix-system.json`.
- [ ] `omanix-theme-osc` prints correct OSC sequences derived from the resolved palette.
- [ ] `omanix.theme.browserPolicy.enable = true` writes managed-policy color JSON for the
      supported browsers via `environment.etc` (no sudoers rule, no runtime privilege).
- [ ] All targets update when the theme changes via the Q2-04 flow.
- [ ] No `omarchy` strings remain; no `sudoers.d/omanix-theme-browser` introduced.
- [ ] `nix flake check` passes; new options appear in the generated options doc.

## Testing
- `nix flake check` passes; `nix build` the browser-policy `environment.etc` content.
- In a tmux session, run `omanix-theme-set-tmux` — colors change live; detach/reattach keeps
  them.
- Run `omanix-theme-set-claude --activate` — `~/.claude/themes/omanix.json` exists and Claude
  Code picks it up.
- `omanix-theme-osc | cat -v` shows expected `\033]11;#…` sequences.
- Build a config with `browserPolicy.enable` — confirm `/etc/chromium/policies/managed/color.json`
  content matches the palette.

## References
- omarchy: `bin/omarchy-theme-set-tmux`, `bin/omarchy-theme-set-claude`,
  `bin/omarchy-theme-set-pi`, `bin/omarchy-theme-set-browser-policy`, `bin/omarchy-theme-osc`,
  `etc/sudoers.d/omarchy-theme-browser` (the mechanism we are *replacing*)
- omanix: `modules/home-manager/apps/{tmux,ai}.nix`, `pkgs/omanix-scripts/{default.nix,src/}`
- Depends on Q2-04 (`omanix-theme-color` resolver + hybrid switch flow).
