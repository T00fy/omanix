# Q1-14: `omanix-bar` + `omanix-restart/refresh-shell` + `omanix-shell-config`

- **Phase:** 1
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q3-01 (bindings use these), Q2-05
- **Size:** M

## Context
Beyond the core `omanix-shell` IPC wrapper (Q1-04), omarchy ships several shell-management CLIs
that users and keybindings call. This ticket ports the remaining ones so the shell is fully
controllable from the command line:

- `omarchy-bar` — manage the bar: `use | reset | defaults | position | transparent | put | move | set`
  (with `--section left|center|right`, `--index N`, `--before/--after <id>`). Reads
  `omarchy-plugin-catalog` for valid widgets.
- `omarchy-bar-text-color` — set bar text color.
- `omarchy-restart-shell` — restart the Quickshell process.
- `omarchy-refresh-shell` — refresh/reload shell config (copy default config, reload).
- `omarchy-shell-config` — read/inspect shell config.
- `omarchy-toggle-bar` — toggle bar visibility.

Port these as `omanix-*` scripts in the existing `pkgs/omanix-scripts` derivation.

## Scope
**In scope:** port the listed shell-management CLIs as `omanix-*`, packaged and wrapped with
their runtime deps; ensure they drive the running shell over `omanix-shell` IPC (Q1-04) and
operate on `~/.config/omanix/shell.json`.
**Out of scope:** the plugin management CLI (`omanix-plugin-*`, Q4-01) even though `omanix-bar`
consults the plugin catalog — depend on `omanix-plugin-catalog` existing if `bar put/move`
requires it, or stub the catalog lookup and note the follow-up; the clipboard/emoji menu CLIs
(Q3-04); theme CLIs (Q2-*).

## Implementation notes
- Sources: omarchy `bin/omarchy-bar`, `bin/omarchy-bar-text-color`, `bin/omarchy-restart-shell`,
  `bin/omarchy-refresh-shell`, `bin/omarchy-shell-config`, `bin/omarchy-toggle-bar`. Port to
  `pkgs/omanix-scripts/src/omanix-*.sh` and add to the derivation's script list.
- **D1:** rename `omarchy-*` → `omanix-*`, `omarchy-shell` calls → `omanix-shell`, config path
  `~/.config/omarchy/shell.json` → `~/.config/omanix/shell.json`, IPC target strings `omarchy.*`
  → `omanix.*`. Since these are hand-ported scripts (not the vendored QML tree), do the rename in
  the ported source directly, consistent with the D1 patterns.
- `omanix-refresh-shell` is the **manual trigger** of Q1-03's reconcile: re-apply the declarative
  base `shell.json` from the store over the user's copy (declared keys win, runtime-only keys
  preserved — same deep-merge as activation), then reload. Mirror omanix's existing
  `omanix-refresh-*` convention if one exists; otherwise follow omarchy's refresh semantics. (It is
  the documented escape hatch for pushing a changed declared value to a running shell without a
  full rebuild.)
- Wrap with runtime deps via the existing `makeWrapper` pattern in
  `pkgs/omanix-scripts/default.nix` (jq, gum where used, `omanix-shell`).
- `omanix-bar`'s `put`/`move` need a widget catalog. If `omanix-plugin-catalog` (Q4-01) is not yet
  available, either declare a soft dependency in this ticket's notes or implement a minimal
  catalog walk over the built-in plugins; document the choice. Do not hard-block on Q4-01.
- Reconcile with omanix's existing `omanix-restart-walker` reference (walker being removed) — this
  set of scripts is the replacement.

## Acceptance criteria
- [x] `omanix-bar`, `omanix-bar-text-color`, `omanix-restart-shell`, `omanix-refresh-shell`,
      `omanix-shell-config`, `omanix-toggle-bar` are built, on PATH, and wrapped with their deps.
      *(Also ships supporting helper `omanix-hyprland-session-locked` for restart lock-safety.)*
- [ ] `omanix-bar position top|bottom`, `omanix-bar transparent on|off`, and
      `omanix-bar use <id>` change the running bar (verified visually) and persist to
      `~/.config/omanix/shell.json`. *(Needs a live session; note D2 — `position`/`transparent`/`use`
      edit the declared bar block, so a rebuild re-applies the Nix-declared values over them.)*
- [ ] `omanix-toggle-bar` shows/hides the bar. *(Needs a live session; flag file +
      `omanix-shell -q omanix.bar syncHidden`.)*
- [ ] `omanix-restart-shell` restarts the shell process cleanly (bar/plugins come back).
      *(Needs a live session. Relaunches via `hyprctl dispatch exec "quickshell -n -p $OMANIX_PATH/shell"`;
      full lock-preservation dance ported.)*
- [x] `omanix-refresh-shell` re-applies the declarative base over `shell.json` (declared keys win, runtime-only keys preserved — same reconcile as activation) and reloads the shell. *(Uses the same `jq -s '.[0] * .[1]'` + declared base as `home.activation.omanixShellConfig`.)*
- [x] `omanix-shell-config` reports current shell config. *(Sourced helper library; run directly it prints the resolved config.)*
- [x] All scripts use `omanix-*` naming and the `~/.config/omanix/` path (no `omarchy` leakage).
- [x] `nix flake check` passes; `nix build .#omanix-scripts` succeeds.

**Deferred:** `omanix-bar use`/`defaults` skip catalog validation when `omanix-plugin-catalog`
(Q4-01) is absent; dropbox/tailscale `defaults` widgets await `omanix-installed-service-*` (Q4-07).

## Testing
- Build: `nix build .#omanix-scripts`, `nix flake check`.
- Runtime (Hyprland session with shell running): exercise each script per acceptance:
  `omanix-bar position bottom` (bar moves), `omanix-bar transparent on` (bar goes transparent),
  `omanix-toggle-bar` twice (hide/show), `omanix-restart-shell` (shell reloads),
  `omanix-refresh-shell` (config reset), `omanix-shell-config` (prints config). Confirm changes
  land in `~/.config/omanix/shell.json`.
- Grep the built scripts for stray `omarchy` / `OMARCHY_PATH` strings — expect none.

## References
- omarchy: `bin/omarchy-bar`, `bin/omarchy-bar-text-color`, `bin/omarchy-restart-shell`,
  `bin/omarchy-refresh-shell`, `bin/omarchy-shell-config`, `bin/omarchy-toggle-bar`,
  `bin/omarchy-plugin-catalog`
- omanix: `pkgs/omanix-scripts/default.nix`, `pkgs/omanix-scripts/src/`, `omanix-shell` (Q1-04),
  seeded `shell.json` (Q1-03)
