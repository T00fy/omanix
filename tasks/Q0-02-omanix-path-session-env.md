# Q0-02: Define `OMANIX_PATH` session-env mechanism

- **Phase:** 0
- **Status:** done
- **Depends on:** Q0-01
- **Blocks:** Q1-03
- **Size:** S

## Context
The vendored Quickshell shell (and every ported `omanix-*` script it calls) locates its own
code/assets through an environment variable. Upstream omarchy uses `$OMARCHY_PATH`, set by the
uwsm session, and `bin/omarchy-shell` hard-fails with "OMARCHY_PATH is not set" if it's absent.
Per decision **D1** we rename this to `$OMANIX_PATH`. Omanix has no uwsm layer, so we must
export `OMANIX_PATH` ourselves into the graphical session so that Hyprland-spawned processes
(the shell, IPC CLIs) inherit it.

This ticket defines *the mechanism and the value* only. Consuming it (autostart, seeding) is
Q1-03.

## Scope
**In scope:** decide the store path `OMANIX_PATH` points at; export it into the session env so
all Hyprland children inherit it; make it overridable.
**Out of scope:** launching quickshell, seeding `shell.json` (both Q1-03); the shell package
itself (Q1-02).

## Implementation notes
- `OMANIX_PATH` should point at the vendored shell package's root — i.e. the store path that
  contains `shell/` (`${pkgs.omanix-shell}` or `${pkgs.omanix-shell}/share/omanix`, whatever
  layout Q1-02 lands on). The shell is launched as `quickshell -n -p $OMANIX_PATH/shell`.
- Omanix already sets Hyprland env vars in
  `modules/home-manager/desktop/hyprland/envs.nix` via
  `wayland.windowManager.hyprland.settings.env` entries (`{ _args = [ "NAME" "VALUE" ]; }`,
  rendered to Lua). **Add `OMANIX_PATH` there** so every Hyprland child inherits it. Example:
  ```nix
  { _args = [ "OMANIX_PATH" "${config.omanix.quickshell.package}/share/omanix" ]; }
  ```
  (Reference `omanix.quickshell.package` or interpolate the pkg directly — align with how Q1-02/Q1-03
  expose the package. Coordinate the exact attribute with Q1-03.)
- Hyprland `env` entries are exported to the compositor and all spawned processes, which covers
  autostart + keybind-invoked scripts. Confirm this is sufficient vs. also needing it in the
  systemd `--user` environment (if any shell piece runs as a user service, it must also see
  `OMANIX_PATH` — if so, add via `systemd.user.sessionVariables` or `home.sessionVariables`).
- Do NOT re-derive fallback paths from `$HOME` inside scripts; per omarchy convention scripts
  rely solely on `OMANIX_PATH`. Keep that invariant.
- Make the value overridable: expose an `omanix.quickshell.path` (or reuse `omanix.quickshell.package`)
  option so advanced users / the `dev` workflow can point at a checkout.

## Acceptance criteria
- [ ] `OMANIX_PATH` is exported into the Hyprland session and inherited by child processes.
- [ ] The value resolves to a directory containing `shell/shell.qml` (once Q1-02 lands; until then, to the intended store path).
- [ ] The mechanism also covers any user systemd services that need it (documented decision even if none exist yet).
- [ ] The path is overridable via a module option.
- [ ] `nix flake check` passes; options doc still builds.

## Testing
```bash
cd /home/toofy/projects/omanix
nix flake check
nix build .#packages.x86_64-linux.docs   # options doc still builds
```
Runtime (in a Hyprland session once Q1-02/Q1-03 exist): open a terminal spawned by Hyprland and
`echo $OMANIX_PATH` → prints the store path; `ls $OMANIX_PATH/shell/shell.qml` exists.

## References
- omarchy: `bin/omarchy-shell` (requires `OMARCHY_PATH`); AGENTS.md "Runtime Environment"
- omanix: `modules/home-manager/desktop/hyprland/envs.nix`, `modules/home-manager/desktop/hyprland/autostart.nix`
