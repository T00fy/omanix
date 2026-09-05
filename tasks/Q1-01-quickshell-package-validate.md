# Q1-01: Validate/package Quickshell with required Qt service modules

- **Phase:** 1
- **Status:** done
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
- [x] A `quickshell` package builds via the omanix flake (built from the flake's locked nixpkgs; fetched from `cache.nixos.org` — no compile).
- [x] All required modules import successfully (verified by both smoke tests below, not assumed).
- [x] `pkgs.quickshell` is exposed through the omanix overlay.
- [~] A trivial `ShellRoot` renders in a live Hyprland session — validated **headless** (`quickshell -p … -n`): `ShellRoot` loads and `Configuration Loaded` with no errors. On-screen render in a live Hyprland session not performed in this environment; defer visual confirmation to Q1-03 session integration.
- [x] `nix flake check` passes.
- [x] Findings recorded below + `../PORTING-QUATTRO.md` R1 / Phase 1.

## Findings (2026-09-05)
**Outcome: nixpkgs `quickshell` used as-is — no override, no upstream flake input needed.**

- **Source:** `pkgs.quickshell` **0.3.0** from the flake's pinned nixpkgs (`nixos-unstable`, rev `2fad6eac…`, Qt6 6.11.1). Store path `…-quickshell-0.3.0`, **substitutable from `cache.nixos.org`** (`nix path-info --store https://cache.nixos.org` succeeds) → zero user compile.
- **Why no flags needed:** upstream CMake declares every feature (`HYPRLAND`, `NETWORK`, `BLUETOOTH`, all `SERVICE_*`) **default ON**, and nixpkgs' `cmakeFlags` never disables any. `Hyprland` needs only Wayland; `Networking`/`Bluetooth` and the DBus services (`Mpris`/`Notifications`/`SystemTray`/`UPower`) are **DBus-only at build time** (talk to NetworkManager/BlueZ over DBus at *runtime*; `Qt6::DBus` ships with qtbase). The earlier "nixpkgs omits NetworkManager" concern was a *runtime* dep, not a missing module.
- **Module verification:** all 13 required modules present in the store under `…/lib/qt-6/qml/Quickshell/…`: base, `Io`, `Wayland`, `Hyprland`, `Bluetooth`, `Networking`, `Services/{Mpris,Notifications,Pam,Pipewire,Polkit,SystemTray,UPower}` (plus extras: `I3`, `Widgets`, `DBusMenu`, `Services/Greetd`, …).
- **Smoke tests (both PASS):** (1) scratch `shell.qml` importing all 13 modules → logs `OMANIX_QS_ALL_MODULES_IMPORTED`, `Configuration Loaded`, no import errors. (2) real vendored tree `vendor/omanix-shell` → `Configuration Loaded`, **zero** module-resolution errors.
- **Overlay:** added a documented pass-through `quickshell = prev.quickshell;` in `flake.nix` `overlays.default` — the single point to pin/override if a future nixpkgs bump regresses a module or brings Qt ABI skew.
- **Runtime (not build) follow-ups for later tickets:** the vendored shell run emitted non-blocking warnings that belong downstream, not to Q1-01 —
  - `default shell.json load failed` → correct `$out/shell/config` layout + user seed = **Q1-02**; `builtinShellConfig` fallback covered it.
  - `inotifywait … could not be found` → the plugin watcher needs `inotify-tools` on PATH = **Q1-02/Q1-03** wrapping.
  - `Quickshell.Networking` needs NetworkManager running, `.Bluetooth` needs BlueZ = NixOS-module wiring (`networking.networkmanager.enable`, `hardware.bluetooth.enable`) in **Q1-03/Phase 4**.
- **Note:** there is no `packages.<system>.quickshell` flake output, so `nix build .#quickshell` does not resolve; consume via `pkgs.quickshell` (through the overlay) instead.

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
