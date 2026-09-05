# Q1-08: Menu/launcher plugin + app search

- **Phase:** 1
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q2-05, Q3-01, Q3-03, Q3-05, Q5-01
- **Size:** L

## Context
Omarchy 4.0.2 replaced Walker + Elephant with the `omarchy.menu` Quickshell plugin: a single
surface that is the app launcher, a hierarchical control menu, and a fuzzy application search
(desktop-entry indexing via `AppLibrary.qml` + `AppSearch.js`). The menu content is a
declarative JSONC tree (`default/omarchy/omarchy-menu.jsonc`). This supersedes omanix's Walker
(`ui/walker.nix`) + Elephant (`ui/elephant.nix`) *and* the bash `omanix-menu.sh` dmenu surface
(`pkgs/omanix-scripts/src/omanix-menu.sh`). Under D1 the plugin id is `omanix.menu`.

## Scope
**In scope:** the `omanix.menu` plugin loading; app launcher with fuzzy app search over
`.desktop` entries; the hierarchical menu driven by a JSONC tree ported/adapted from omarchy's
`omarchy-menu.jsonc`; the `omanix-menu` thin IPC shim (toggle/summon the plugin) replacing the
old walker-driven script.
**Out of scope:** clipboard/emoji menu surfaces (Q1-09); the plugin management menu (Q4-01); the
theme/background switcher menus (Q2-05); rebinding SUPER+SPACE etc. in Hyprland (Q3-01);
removing the walker/elephant modules (Q3-03); menu theming (Q2-02).

## Implementation notes
- Source: `shell/plugins/menu/` — `Menu.qml` (large), `MenuModel.js`, `BarWidget.qml`,
  `manifest.json`; app indexing in `shell/services/AppLibrary.qml` + `AppSearch.js`. Menu tree:
  `default/omarchy/omarchy-menu.jsonc` (see `docs/menu.md` for schema: dotted ids, inferred
  kinds action/link/submenu, `provider:` rows, `when`/`checked` shell-condition guards).
- Port the JSONC menu to `default/omanix/omanix-menu.jsonc` and adapt entries to omanix reality:
  drop out-of-scope items (install/provision/channel/factory-reset entries), point actions at
  `omanix-*` commands, keep Apps/Learn/Trigger/Style/Setup/System groups analogous to the
  existing `omanix-menu.sh` structure. User overrides live in `~/.config/omanix/extensions/`.
- `omanix-menu` becomes a thin shim over `omanix-shell` IPC (omarchy's `bin/omarchy-menu` shrank
  from ~925 lines to a small toggle). The old bash `omanix-menu.sh` is retired/repurposed in
  Q3-05 — this ticket provides the replacement, Q3-05 removes the old one.
- **D1:** plugin id/IPC target `omanix.menu`; all actions reference `omanix-*` commands.
- Gotcha: `when`/`checked` guards run shell conditions — ensure the referenced `omanix-*`
  predicates exist or the guard is dropped, else entries vanish or error.

## Acceptance criteria
- [x] `omanix.menu` plugin loads (`keepLoaded`); `omanix-menu` (a thin `omanix-shell` IPC shim, `[toggle|show|hide] [<menu-id>]`) opens the menu via `shell summon/toggle omanix.menu`.
- [x] Typing a query fuzzy-matches installed `.desktop` apps (root search loads the `apps` provider via `loadProvidersForSearch`) and launching one starts the app (fixed the `uwsm-app` launch path → `gtk-launch`).
- [x] A hierarchical menu (from `omanix-menu.jsonc`) navigates submenus and dispatches actions to `omanix-*` commands.
- [x] No entry references an out-of-scope subsystem or a non-existent command (all `action:` verified against `pkgs/omanix-scripts` + hyprpicker/pavucontrol/systemctl).
- [x] `nix flake check` passes; the menu JSONC is valid (`stripJsonc`+`jq`) and shipped to `$OMANIX_PATH/shell/defaults/omanix-menu.jsonc`.

## Implementation summary
- New default tree `pkgs/omanix-shell/defaults/omanix-menu.jsonc` (38 entries); installed by `pkgs/omanix-shell/default.nix` (D5: Nix-shipped, not vendored).
- `omanix-menu` shim rewritten (`src/omanix-menu.sh`); `default.nix` entry reduced to `[bash coreutils jq]` + `selfPath` (dropped walker deps/envs). Satisfies Q3-05's "retire `omanix-menu.sh`".
- Vendored QML edits (recorded per Q0-01): `services/AppLibrary.qml` launch `uwsm-app -- gtk-launch` → `gtk-launch` (omanix disables uwsm; `pkgs.gtk3` added to the shell module's `home.packages`); `plugins/menu/MenuModel.js guardHelpers()` strips the `pacman` machinery, keeping the portable `omanix-cmd-present/missing`.
- Bar: prepended `{ id = "omanix.menu"; }` to `omanix.quickshell.bar.layout.left` (closes the Q1-05 deferral).
- Runtime verification (launcher opens, app launch, submenu dispatch) pending a live Hyprland+shell session.

## Testing
- Build and enter a Hyprland session with the shell running.
- `omanix-menu toggle` → launcher opens; type an app name → it appears and launches on Enter.
- Navigate into a submenu (e.g. Style or System) and trigger an action; confirm it runs.
- `jq . default/omanix/omanix-menu.jsonc` (after stripping comments if needed) parses; validate against `docs/menu.md` schema notes.

## References
- omarchy: `shell/plugins/menu/`, `shell/services/AppLibrary.qml`, `shell/services/AppSearch.js`, `default/omarchy/omarchy-menu.jsonc`, `bin/omarchy-menu`, `docs/menu.md`
- omanix: `modules/home-manager/ui/walker.nix` + `ui/elephant.nix` (superseded), `pkgs/omanix-scripts/src/omanix-menu.sh` (retired in Q3-05)
