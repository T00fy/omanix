# Q2-07: Reconcile stale theme docs (README/CLAUDE)

- **Phase:** 2
- **Status:** done
- **Depends on:** none
- **Blocks:** none
- **Size:** S

## Context
Omanix docs are stale about themes. `README.md` and `CLAUDE.md` describe the theme situation as
"only Tokyo Night" and the 3.8-era waybar/walker/mako stack, but `lib/themes.nix` already ships
**two** themes (`tokyo-night`, `catppuccin-mocha`), and the quattro effort changes the desktop
substantially. This ticket fixes the theme-count/stack claims so docs match reality. It has no
code dependencies and can be done anytime.

## Scope
**In scope:** Correct theme count/list and any "no runtime theme switching" and desktop-stack
claims that are now (or are becoming) false; keep the options doc consistent.
**Out of scope:** Broad rewrites of README for the whole quattro migration — only fix the
theme-related and clearly-stale statements. Do not document features that aren't merged yet as if
they exist.

## Implementation notes
- Grep for stale claims: `rg -n "Tokyo Night|only .* theme|runtime theme|waybar|walker|mako|swayosd" README.md CLAUDE.md docs/`.
- Update the theme list to enumerate what `lib/themes.nix` actually contains
  (`builtins.attrNames omanixLib.themes`), or better, phrase it so it doesn't drift (point at the
  source / generated options doc).
- If any statement asserts "no runtime theme switching," either leave it accurate for now or, if
  Q2-04 has landed, update it to describe the D2 hybrid model (declared theme is source of truth;
  runtime switch is ephemeral). Do not claim runtime switching before it merges.
- Keep tone/format consistent with the existing docs. The generated options reference
  (`packages.x86_64-linux.docs`) must still build.

## Acceptance criteria
- [ ] README/CLAUDE no longer claim only Tokyo Night exists; both shipped themes are reflected (or sourced from the theme list).
- [ ] No remaining doc statement contradicts the actual `lib/themes.nix` theme set.
- [ ] Stack/theming claims are either accurate for the current branch state or clearly marked as planned.
- [ ] Options doc still builds.

## Testing
- `rg` shows no remaining stale theme-count claims.
- `nix build .#docs` (options reference) succeeds.
- `nix flake check` passes.

## Resolution
Corrected the theme-count contradiction: `README.md` ("ships with Tokyo Night") and
`CLAUDE.md` ("only Tokyo Night exists") now enumerate both shipped themes (Tokyo Night +
Catppuccin Mocha) and point at `lib/themes.nix` as the source of truth to resist drift. Left
the "no runtime theme switching" statements as accurate for the shipped product on `main` — the
D2 hybrid runtime switch lives on the (unmerged) quattro Quickshell stack, and the ticket's
governing constraint is not to claim runtime switching before it merges. Stack references
(waybar/walker/mako/swayosd) left intact: still accurate for the current branch state (Phase 3
retirement hasn't landed); a broader quattro doc pass is out of scope.

## References
- omanix: `README.md`, `CLAUDE.md`, `lib/themes.nix`, `docs/`, `PORTING-QUATTRO.md`
