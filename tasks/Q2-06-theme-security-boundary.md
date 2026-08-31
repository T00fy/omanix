# Q2-06: Theme security boundary (deny code from cloned themes)

- **Phase:** 2
- **Status:** todo
- **Depends on:** Q2-04
- **Blocks:** none
- **Size:** S

## Context
Omarchy 4.0.2 hardened `omarchy-theme-set` so that a theme installed from an untrusted git clone
may ship **color data only**. Files that execute — `.lua`, terminal configs, `vscode.json` —
from an installed (non-first-party) theme are denied (`INSTALLED_THEME_DENIED`), because a theme
is otherwise a code-execution vector. This ticket ports that boundary into `omanix-theme-set`.

Note: omanix themes are **declared in-repo** (`lib/themes.nix`), not user-git-installed, so the
attack surface is smaller today. But if omanix ever supports user-supplied/cloned themes (or a
user points a theme dir at arbitrary content), this guard must exist. Port it so the capability
is safe by construction.

## Scope
**In scope:** Port the allow/deny logic distinguishing trusted (first-party/declared) theme
content from untrusted installed themes; deny executable/code files from untrusted sources.
**Out of scope:** Building a full third-party theme-install flow (omanix themes are declarative);
the plugin security model (that is Q4-01's concern).

## Implementation notes
- Source: `git -C ../omarchy show v4.0.2:bin/omarchy-theme-set` — locate the `INSTALLED_THEME_DENIED`
  handling and the list of denied file types (`.lua`, terminal configs, `vscode.json`, anything
  that executes) vs. allowed color data (`colors.toml`, `shell.toml`, images).
- In `omanix-theme-set` (Q2-04), classify a theme source as trusted (from the omanix store / declared
  set) vs untrusted (an arbitrary path the user pointed at). For untrusted sources, copy/apply only
  the allowlisted color/asset files; refuse and warn on denied files.
- Keep the allowlist explicit and documented. Prefer allowlist (permit known-safe) over denylist.
- Since omanix's shipped themes come from the trusted store, they bypass the restriction — the guard
  only bites on untrusted sources.

## Acceptance criteria
- [ ] `omanix-theme-set` applied to a trusted (declared/store) theme applies fully.
- [ ] `omanix-theme-set` applied to an untrusted source containing a `.lua`/terminal/`vscode.json` file refuses those files (with a clear message) and applies only color data.
- [ ] The allowlist of safe files is explicit in the script and documented.

## Testing
- Craft a fake untrusted theme dir containing `colors.toml` + a `malicious.lua`; run `omanix-theme-set --file <dir>` (or the equivalent untrusted path); assert the `.lua` is refused and `colors.toml` applied.
- Trusted/declared theme still applies fully.
- `nix build` scripts package; `nix flake check` passes.

## References
- omarchy: `bin/omarchy-theme-set` (`INSTALLED_THEME_DENIED`), `docs/theming.md`
- omanix: `pkgs/omanix-scripts/src/omanix-theme-set.sh` (from Q2-04)
