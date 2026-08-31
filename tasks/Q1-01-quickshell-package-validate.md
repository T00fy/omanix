# Q1-01: Validate/package Quickshell with required Qt service modules

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q0-01
- **Blocks:** Q1-02
- **Size:** M

## Context
This is the **keystone risk (R1)** of the whole port. Omarchy 4.0.2 replaced its entire desktop
daemon stack with a single long-running [Quickshell](https://quickshell.org) (QML/Qt6) process.
That process imports a specific set of Quickshell service submodules; if the Nix `quickshell`
build doesn't provide them, the shell won't run and the rest of the plan is blocked. This
ticket is a **spike**: prove a suitably-featured Quickshell builds and runs a trivial
`ShellRoot` in a Hyprland session, and expose it via the omanix overlay/pkgs. Do this before
investing in Q1-02+.

## Scope
**In scope:** obtain a Quickshell package with all required modules; smoke-test it; wire it into
the flake overlay/packages so later tickets can reference `pkgs.quickshell`.
**Out of scope:** vendoring omarchy's `shell/` (Q1-02); any plugins.

## Implementation notes
- **Required modules** the shell imports (from the shell analysis) — all must be present:
  - `Quickshell`, `Quickshell.Io`, `Quickshell.Wayland`, `Quickshell.Hyprland`
  - `Quickshell.Bluetooth`, `Quickshell.Networking`
  - `Quickshell.Services.Mpris`, `.Notifications`, `.Pam`, `.Pipewire`, `.Polkit`,
    `.SystemTray`, `.UPower`
- **First choice:** `pkgs.quickshell` in nixpkgs-unstable (omanix already tracks
  `nixos-unstable`). Check whether it enables the above (some are gated behind build flags /
  optional deps like PAM, Pipewire, UPower, the tray). If a needed feature is off, either
  `.override`/`overrideAttrs` to enable it (add the missing build inputs / cmake flags) or fall
  back to the upstream Quickshell flake (`github:quickshell-mirror/quickshell` / the official
  outfoxxed repo) and consume its package.
- Add the resulting package to `flake.nix` `overlays.default` (alongside `omanix-scripts` etc.)
  as `quickshell = ...;` so downstream tickets use `pkgs.quickshell`.
- Verify the QML modules are actually importable at runtime, not just that the binary builds —
  missing optional modules fail at import time, not build time.

## Acceptance criteria
- [ ] A `quickshell` package builds via the omanix flake (`nix build`).
- [ ] All required modules import successfully (verified by the smoke test below, not assumed).
- [ ] `pkgs.quickshell` is exposed through the omanix overlay.
- [ ] A trivial `ShellRoot` renders in a live Hyprland session.
- [ ] `nix flake check` passes.
- [ ] Findings recorded: which modules needed extra flags/inputs, and whether nixpkgs or the upstream flake was used (note in this ticket + `../PORTING-QUATTRO.md` R1).

## Testing
```bash
cd /home/toofy/projects/omanix
nix build .#quickshell            # or the overlay attr chosen
nix flake check
```
Module-import smoke test — create a scratch `test-shell.qml` importing every required module and
a minimal `ShellRoot { }`, then run it in a Hyprland session:
```bash
cat > /tmp/test-shell.qml <<'EOF'
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pam
import Quickshell.Services.Pipewire
import Quickshell.Services.Polkit
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
ShellRoot { Component.onCompleted: console.log("omanix quickshell: all modules imported") }
EOF
quickshell -p /tmp/test-shell.qml    # must log the line with no import errors
```
Pass = the log line prints and no "module not installed" / import errors appear.

## References
- Quickshell docs: https://quickshell.org
- omarchy: `shell/shell.qml` (`ShellRoot` entry), imports across `shell/**/*.qml`; launched as `quickshell -n -p $OMARCHY_PATH/shell`
- omanix: `flake.nix` overlay (`overlays.default`, lines ~70-81)
