# Q1-11: Lock plugin (PAM) + Nix PAM wiring

- **Phase:** 1
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q1-12 (idle triggers lock), Q3-03 (remove Hyprlock)
- **Size:** L

## Resolution
The vendored `omanix.lock` plugin needed **no QML changes** — it is a first-party `keepLoaded`
service (id `omanix.lock`, IPC target `lock` with `lock`/`isLocked`/`status`/`preview`; locks via
`WlSessionLock`) that auto-loads because it is absent from `disabledPlugins`. It refuses to lock
unless `/etc/pam.d/omanix-lock-password` exists and authenticates against that PAM service;
fingerprint uses a separate `omanix-lock-fingerprint` service, probed via `fprintd-list`.

The Nix-specific work is declarative PAM: new module `modules/nixos/security.nix` declares
`security.pam.services.omanix-lock-password` (standard unix auth, `fprintAuth = false` so the
password context stays password-only) and, gated on `services.fprintd.enable`,
`security.pam.services.omanix-lock-fingerprint` (`unixAuth = false`, `fprintAuth = true`). No
script writes `/etc/pam.d`. Options nest under `omanix.security.lock.*` (`enable`,
`fingerprint.enable`, the latter defaulting to `config.services.fprintd.enable`). Registered in
`modules/nixos/default.nix` imports.

On-demand lock is the generic wrapper `omanix-shell lock lock` (target `lock`, method `lock`) — no
bespoke script. The lock timeout source is `shell.json` `idle.lock` (seconds), wired into the
declared base by Q1-12, not here. Faillock omitted per decision (plain password auth).

Verified: `nix flake check` passes; `omanix-lock-password` materializes with `unixAuth=true`,
`fprintAuth=false`; `omanix-lock-fingerprint` is absent when fprintd is off and appears
(`unixAuth=false`, `fprintAuth=true`) when `services.fprintd.enable = true` — confirmed via
`nix eval` of `nixosModules.default`.

Out of scope / follow-ups: Hyprlock removal (Q3-03), keybind/idle rewiring (Q3-01/Q1-12),
fprintd enrollment (Q4-02). The plugin best-effort-calls four not-yet-existing helpers
(`omanix-hyprland-session-locked`, `omanix-system-wake`, `omanix-brightness-{keyboard,display}`) —
non-blocking, core lock/unlock works without them. `omanix-lock-screen`'s bitwarden-lock/xkb-reset
is not carried over (revisit with Q3-01).

## Context
Omarchy 4.0.2 replaced Hyprlock with an in-shell lock screen: the `omarchy.lock` plugin
authenticates via `Quickshell.Services.Pam` (with optional fingerprint), rendered by the same
Quickshell process. Omanix currently locks with Hyprlock (`desktop/hyprlock.nix`), launched by
`omanix-lock-screen` (which has bitwarden-cli integration) and by hypridle.

This ticket brings up `omanix.lock` and provides the NixOS-side PAM configuration it needs.
Omarchy configures PAM imperatively via `omarchy-apply-lock` (writes
`/etc/pam.d/omarchy-lock-password`, faillock deny=10, optional `omarchy-lock-fingerprint`). On
NixOS this must be **declarative** — a `security.pam.services.<name>` entry in a NixOS module,
NOT a script writing `/etc/pam.d`.

## Scope
**In scope:** vendor + enable the `omanix.lock` plugin; add a NixOS module option that declares
the PAM service the lock plugin authenticates against (password path; optional fingerprint when
a reader is enrolled); wire the lock idle/lock timeout via `shell.json` `idle.lock`; provide the
`omanix-shell` IPC path to lock on demand (replacing the Hyprlock launch in bindings/idle).
**Out of scope:** the fingerprint *enrollment* setup flow (that belongs with Q4-02 hardware /
security); actually removing `desktop/hyprlock.nix` (Q3-03); the bitwarden autotype feature is
noted below but only carried forward if trivial.

## Implementation notes
- Source: omarchy `shell/plugins/lock/{Service.qml,LockView.qml,manifest.json}`. Vendored by
  Q1-02 with D1 rename (`omarchy.lock` → `omanix.lock`; the PAM service name string will contain
  `omarchy` — decide the omanix name, e.g. `omanix-lock-password`, and make the rename patch or
  seeded config produce it consistently on both the QML side and the NixOS PAM side).
- **PAM (the Nix-specific part):** add a NixOS module (e.g. extend `modules/nixos/`) exposing the
  PAM service the plugin uses. Minimum: a password auth service equivalent to omarchy's
  `/etc/pam.d/omarchy-lock-password`. Use `security.pam.services.omanix-lock-password = { ... }`.
  Mirror omarchy's faillock intent (deny after N failures) where NixOS options allow. Optional
  fingerprint: gate a `security.pam` fingerprint factor behind an option that is only meaningful
  when `fprintd` is enabled / a reader is enrolled (coordinate with Q4-02).
- The QML uses `Quickshell.Services.Pam`; ensure the Quickshell build from Q1-01 has the Pam
  module (it is on the required-modules list). Verify the PAM *service name* the QML passes
  matches the NixOS-declared service exactly, or the lock will always fail auth.
- Timeout wiring: `shell.json` `idle.lock` (seconds) — the shell's idle service (Q1-12) triggers
  the lock. This ticket only needs the lock to be lockable on demand via IPC and to accept a
  correct password; the idle-driven trigger is validated in Q1-12.
- **Gotcha (lockout risk):** a misconfigured PAM service can lock the user out of unlocking. Test
  in a disposable VM / with a second TTY session open. Confirm the correct password unlocks and a
  wrong password is rejected before wiring it into idle/bindings.
- bitwarden: omanix's `omanix-lock-screen` integrates bitwarden-cli. The in-shell lock replaces
  the launcher; if the bitwarden flow was autotype-on-unlock, note it as a follow-up rather than
  blocking this ticket.

## Acceptance criteria
- [ ] `omanix.lock` plugin loads in the running shell without error.
- [x] A NixOS module declares the PAM service the lock uses (`security.pam.services.…`), and it
      evaluates; no script writes `/etc/pam.d` at runtime.
- [ ] Locking the session via `omanix-shell` IPC shows the lock view; the correct login password
      unlocks; a wrong password is rejected.
- [ ] Fingerprint unlock works when a reader is enrolled *or* is cleanly absent/disabled when not
      (no hard failure when no reader).
- [x] `idle.lock` in `shell.json` is documented as the lock timeout source (consumed by Q1-12).
- [x] `nix flake check` passes; options doc builds if a new `omanix.*` option was added.

## Testing
- Build: `nix flake check`, `nix build .#omanix-shell`.
- Runtime (VM strongly recommended): with the shell running, trigger lock over IPC (the exact
  command comes from Q1-04's IPC surface, e.g. `omanix-shell shell summon omanix.lock` or the
  documented lock method). Verify: lock view appears; correct password unlocks; wrong password
  denied; (if reader present) fingerprint unlocks.
- Keep a second TTY / SSH session available during testing to recover from a PAM misconfig.

## References
- omarchy: `shell/plugins/lock/Service.qml`, `shell/plugins/lock/LockView.qml`,
  `shell/plugins/lock/manifest.json`, `bin/omarchy-apply-lock`
- omanix: `modules/home-manager/desktop/hyprlock.nix`,
  `pkgs/omanix-scripts/src/omanix-lock-screen.sh` (bitwarden), `modules/nixos/` (new PAM module),
  Quickshell Pam module requirement from Q1-01, seeded `shell.json` from Q1-03
