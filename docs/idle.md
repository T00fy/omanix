# Idle & Lock

Omanix has a single idle owner: the Quickshell `omanix.idle` service. There is
no separate idle daemon (hypridle was removed). The model matches upstream
Omarchy.

## Idle stages

| Time    | Action                                      | Option                        |
|---------|---------------------------------------------|-------------------------------|
| 2.5 min | Fullscreen screensaver (branded ASCII logo) | `omanix.idle.screensaver`     |
| 15 min  | Screen locks (`omanix.lock` shell plugin)   | `omanix.idle.lock`            |

Dismissing the screensaver (any input) before the lock deadline cancels the
cycle, so an active dismissal never leaves the machine on its way to locked.

There is deliberately **no idle-dim, no idle-DPMS-off, and no
auto-suspend-on-idle**:

- The fullscreen screensaver is the "blanking" — a separate DPMS-off stage
  would only add an unwakeable-display failure mode.
- `logind`'s `IdleAction` is unreliable on Wayland/Hyprland, so it is not a
  substitute for idle-suspend. Re-adding auto-suspend-on-idle would mean
  re-introducing an idle daemon.

## Configuring timeouts

```nix
omanix.idle = {
  screensaver = { enable = true; timeout = 150; };   # seconds
  lock        = { enable = true; timeout = 900; };
};
```

Set a stage's `enable = false` to disable just that stage.

## Stay Awake

`omanix-toggle-idle` flips `~/.local/state/omanix/indicators/stay-awake`; the
idle service watches that file and suspends its timers while it exists. This is
the one shared source of truth for the "Stay Awake" menu entry, the
`Super+Ctrl+I` keybind, and the bar widget — they always agree.

```
omanix-toggle-idle             # toggle
omanix-toggle-idle stay-awake  # force stay-awake
omanix-toggle-idle allow-idle  # force normal idling
omanix-toggle-idle status      # JSON state (for the widget)
```

## Lock before sleep

Locking before the system suspends is a dedicated, race-free service —
independent of the idle timers and of Stay Awake (the machine always locks
before it sleeps).

`systemd.user.services.omanix-lock-before-sleep`
(`modules/home-manager/desktop/lock-before-sleep.nix`) holds a `systemd-inhibit
--what=sleep --mode=delay` inhibitor and watches the system bus for logind's
`PrepareForSleep(true)` signal. On that signal it locks via `omanix-system-lock`
and waits until the lock surface reports `secure` before releasing the
inhibitor, so suspend only proceeds once the machine is actually locked — no
flash of unlocked desktop on resume.

The delay window is bounded by `services.logind.settings.Login.InhibitDelayMaxSec`
(set to 15s in `modules/nixos/idle.nix`); the lock poll is capped just below it.
Gated on `omanix.security.lock.enable` (the lock PAM services must exist for the
lock to reach `secure`).

This covers desktop manual suspend, laptop manual suspend, and laptop lid-close
(logind's default `HandleLidSwitch=suspend`) identically.
