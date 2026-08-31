# Q4-11: herdr terminal multiplexer

- **Phase:** 4
- **Status:** todo
- **Depends on:** none
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 ships **herdr**, a native terminal multiplexer branded the "agent manager,"
alongside tmux (it does not replace tmux). It has a TOML config that mirrors the tmux keymap
1:1 (same `Ctrl+Space` prefix), a JSON/socket API driven by a `herdr` CLI, and dev-layout
shell functions oriented at running AI agents. This ticket brings herdr to omanix.

**Good news:** `herdr` is already in nixpkgs (`pkgs.herdr`, 0.8.2, "Agent multiplexer that
lives in your terminal") — no custom packaging needed. Verify it's the right one at pickup.

omarchy source:
- `config/herdr/config.toml` — TOML config; mirrors the tmux config (session→workspace,
  window→tab, pane→pane); `[theme]`/`[theme.custom]`/`[ui]` sections.
- `bin/omarchy-launch-terminal-herdr` → `exec omarchy-launch-terminal herdr`.
- `bin/omarchy-restart-herdr` → `herdr server reload-config` if the server is running.
- `bin/omarchy-refresh-herdr` → overwrite user config with the default, then restart.
- `bin/omarchy-menu-herdr-keybindings` → keybindings viewer (parallels tmux one).
- `default/bash/fns/herdr` — shell functions `hdl <ai> [<ai2>]` (editor/AI/terminal layout),
  `hds` (dev square: editor / `hunk diff --watch` / terminal / opencode), `hdlm <ai>` (one
  `hdl` tab per subdir), `hsl <count> <cmd>` (grid "swarm" of N panes). They drive herdr's
  JSON API and read `HERDR_PANE_ID` / `HERDR_TAB_ID` / `HERDR_WORKSPACE_ID`.
- Keybindings: `Super+Ctrl+Return` → herdr; `Super+Ctrl+K` → herdr keybindings viewer.
  Keybindings help is auto-generated from herdr's own config (tab-bar status config).

## Scope
**In scope:** enable `pkgs.herdr`; ship a themed `config.toml` (from the palette); ported
`omanix-launch-terminal-herdr`, `omanix-restart-herdr`, `omanix-refresh-herdr`,
`omanix-menu-herdr-keybindings`; the `hdl/hds/hdlm/hsl` shell functions; Hyprland bindings
`Super+Ctrl+Return` and `Super+Ctrl+K`.
**Out of scope:** replacing tmux (both coexist); the agent CLIs the fns invoke (opencode/claude
etc. come from Q5 / `apps/ai.nix`); `hunk` tooling (note as an optional dep of `hds`).

## Implementation notes
- New module `modules/home-manager/apps/herdr.nix` with `omanix.apps.herdr.enable`
  (default false), packaging `pkgs.herdr` and writing `~/.config/herdr/config.toml`.
- **Theming:** herdr reuses the tmux OSC approach (see Q4-10). Generate the declared theme
  into `config.toml`'s `[theme]` from the palette; runtime switch via
  `omanix-theme-set-tmux`-style handling (ephemeral). Coordinate with Q4-10.
- **Shell fns:** omanix uses zsh (`core/shell.nix`) and has tmux fns in `apps/tmux.nix`. Add
  the `h`-prefixed herdr fns (`hdl/hds/hdlm/hsl`) as zsh functions, driving `herdr` JSON API.
  Keep them parallel to omanix's existing tmux dev-layout fns if present.
- **Bindings:** add to `modules/home-manager/desktop/hyprland/bindings.nix` using the existing
  `mkExec`/`mkBind` helpers: `Super+Ctrl+Return` → `omanix-launch-terminal-herdr`,
  `Super+Ctrl+K` → `omanix-menu-herdr-keybindings`. Attach descriptions (they feed the
  keybindings viewer). Gate behind `omanix.apps.herdr.enable` if bindings are conditional.
- **D1:** rename `omarchy-*` → `omanix-*`; check the `config.toml` and fns for `omarchy`
  string refs (paths, command names).
- `omanix-launch-terminal-herdr` should call omanix's terminal launcher
  (`omanix-launch-terminal`/`omanix-launch-tui` — check `pkgs/omanix-scripts/src/`) with
  `herdr`.
- Note optional deps: `hds` uses `hunk diff --watch` and `opencode` — document that those
  panes no-op/error gracefully if the tools aren't installed.

## Acceptance criteria
- [ ] `omanix.apps.herdr.enable = true` installs herdr and writes a themed
      `~/.config/herdr/config.toml`.
- [ ] `Super+Ctrl+Return` opens a herdr terminal; `Super+Ctrl+K` shows the herdr keybindings.
- [ ] `omanix-restart-herdr` reloads config on a running server; `omanix-refresh-herdr` resets
      config to default and restarts.
- [ ] `hdl <agent>` opens the editor/AI/terminal layout; `hsl <n> <cmd>` opens an n-pane grid.
- [ ] herdr theme matches the declared palette; runtime theme switch retints it (ephemeral).
- [ ] tmux still works unchanged (herdr does not replace it).
- [ ] No `omarchy` strings remain.
- [ ] `nix flake check` passes; the option appears in the generated options doc.

## Testing
- `nix eval nixpkgs#herdr.meta.description` confirms the package identity.
- `nix build` the herdr module; `nix flake check` passes.
- Runtime: enable herdr, press `Super+Ctrl+Return`, confirm herdr launches with the themed
  config; run `hdl claude` and confirm the layout; run `hsl 4 htop`.
- `omanix-menu-herdr-keybindings` lists the bindings from the config.

## References
- omarchy: `config/herdr/config.toml`, `default/bash/fns/herdr`,
  `bin/omarchy-launch-terminal-herdr`, `bin/omarchy-refresh-herdr`,
  `bin/omarchy-restart-herdr`, `bin/omarchy-menu-herdr-keybindings`
- omanix: new `modules/home-manager/apps/herdr.nix`, `modules/home-manager/apps/tmux.nix`
  (reference), `modules/home-manager/desktop/hyprland/bindings.nix`,
  `pkgs/omanix-scripts/{default.nix,src/}`, `modules/home-manager/core/shell.nix`
- nixpkgs: `pkgs.herdr`
- Related: Q4-10 (shared tmux/herdr theming approach).
