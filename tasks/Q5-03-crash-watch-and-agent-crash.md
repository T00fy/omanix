# Q5-03: Crash-watch service + `omanix-agent-crash`

- **Phase:** 5
- **Status:** todo
- **Depends on:** Q5-01 (agent launcher/prompt)
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 can offer to diagnose a crashed process with AI. Three pieces:
- `omarchy-crash-watch` — a systemd **user** service that tails `journalctl` for the
  systemd-coredump `MESSAGE_ID`, dedupes per-process, filters to the current UID, and on a
  user-process crash sends a critical notification "Process crashed / Click to diagnose with
  AI". Only fires when a default agent is set; skips its own machinery; respects a per-program
  mute (`crash-ignore/<name>`).
- `omarchy-agent-crash <pid> [comm] [exe] [signal]` — builds a prompt from `coredumpctl` facts
  and pipes it to `omarchy-agent --prompt`, pointing the agent at the `diagnose-crash` skill.
- `omarchy-toggle-crash-capture` — flips a toggle (`~/.local/state/omarchy/toggles/crash-capture-off`)
  and starts/stops the service.

The service is gated: `After/PartOf=graphical-session.target`, `ConditionEnvironment=WAYLAND_DISPLAY`,
`ConditionPathExists=!%h/.local/state/omarchy/toggles/crash-capture-off`.

## Scope
**In scope:** Port the three scripts and declare the systemd user unit via home-manager
(`systemd.user.services`). Wire the toggle into the menu (Trigger › Crash Capture). Requires
`systemd-coredump` enabled system-wide.
**Out of scope:** the `diagnose-crash` skill content itself (that ships in Q5-04); the usage
widget (Q5-02).

## Implementation notes
- **D1:** rename scripts `omarchy-*`→`omanix-*`; state paths `~/.local/state/omarchy/…`→
  `~/.local/state/omanix/…`; `MESSAGE_ID`/journal parsing stays the same.
- **Declarative unit:** don't ship a raw `.service` file to be enabled imperatively. Define it
  in home-manager: `systemd.user.services.omanix-crash-watch` with `Unit.After`/`PartOf` =
  `graphical-session.target`, `Unit.ConditionEnvironment = "WAYLAND_DISPLAY"`, and the
  `ConditionPathExists=!%h/.local/state/omanix/toggles/crash-capture-off` gate, `Service.ExecStart`
  pointing at the packaged `omanix-crash-watch`, `Restart=always`, `WantedBy=graphical-session.target`.
  Gate the whole unit behind an option, e.g. `omanix.apps.ai.crashCapture.enable` (default off).
- The toggle script starts/stops via `systemctl --user`. Since the unit is declared, "off" is
  the presence of the toggle file (the `ConditionPathExists`) — keep that mechanism so a
  disabled watcher stays disabled across logins without `systemctl disable`.
- `omanix-agent-crash` depends on `omanix-agent --prompt` (Q5-01) and `coredumpctl`
  (systemd-coredump). It must skip its own `omanix-crash-*`/`omanix-agent-*` processes and only
  fire when a default agent is set (`omanix-default-agent` returns non-empty).
- System requirement: ensure `systemd.coredump.enable` (or equivalent) is on where this module
  is used; document it. The nixos module may need to assert/enable it.
- Notification uses omanix's notification sender with an `--exec` action; confirm omanix has an
  equivalent to `omarchy-notification-send --exec` (it runs the action as safe argv). If not,
  add a minimal wrapper and note it.

## Acceptance criteria
- [ ] `omanix-crash-watch`, `omanix-agent-crash`, `omanix-toggle-crash-capture` exist and are on PATH.
- [ ] `systemd.user.services.omanix-crash-watch` is declared, gated by the toggle-file condition and `WAYLAND_DISPLAY`, and behind an off-by-default option.
- [ ] The watcher only notifies when a default agent is set and the toggle file is absent.
- [ ] Clicking the notification runs `omanix-agent-crash` → `omanix-agent --prompt` pointed at the `diagnose-crash` skill.
- [ ] `omanix-toggle-crash-capture` flips the toggle file and starts/stops the user service.
- [ ] Menu entry (Trigger › Crash Capture) invokes the toggle.
- [ ] Requires `systemd-coredump`; the module documents/asserts it.
- [ ] No `omarchy`/`OMARCHY_PATH` strings remain; `nix flake check` passes.

## Testing
- `nix flake check`; build the scripts package.
- Enable the option in a test HM config; confirm `systemctl --user status omanix-crash-watch`
  shows it active only when a default agent is set and the toggle file is absent.
- Trigger a crash (`sleep 100 & kill -SEGV %1` on a coredump-enabled host) → expect a
  "diagnose with AI" notification; clicking launches the agent with a crash prompt.
- `omanix-toggle-crash-capture` twice → service stops then starts; toggle file appears/disappears.
- Grep ported scripts for `omarchy` → no matches.

## References
- omarchy: `bin/omarchy-crash-watch`, `bin/omarchy-agent-crash`, `bin/omarchy-toggle-crash-capture`, `default/systemd/user/omarchy-crash-watch.service`, menu `trigger.toggle.crash-capture`
- omanix: `pkgs/omanix-scripts/src/`, `modules/home-manager/apps/ai.nix` (add the option + unit), `modules/nixos/` (assert `systemd-coredump`)
