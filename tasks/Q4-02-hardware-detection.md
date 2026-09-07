# Q4-02: Hardware detection (`omanix-hw-*`)

- **Phase:** 4
- **Status:** done
- **Depends on:** none
- **Blocks:** none
- **Size:** M

> **Scope note (resolved):** in addition to the 8 `omanix-hw-*` probes, this ticket also shipped
> the power panel's two data emitters `omanix-battery-status --shell` + `omanix-system-stats`.
> `PORTING-QUATTRO.md:214` (Q1-13) buckets those two — plus `omanix-hw-laptop-closed` — under
> Q4-02 as the shell's unimplemented callers, and no other ticket owns them. They read live
> sensor state (battery %, charge rate, CPU/mem load) that Nix cannot declare, so they are
> runtime scripts by nature, the same category as the probes.

## Context
Omarchy 4.0.2 added a family of hardware-detection predicates used by the shell and other
scripts to make runtime decisions (is this a laptop? is the lid closed? is there a webcam?).
They are small sysfs/ACPI/lspci probes returning exit codes or short strings. Omanix has no
equivalent today. Some of these are genuinely runtime queries (lid state changes while running);
others are static facts better expressed as NixOS `hardware.*`/module options.

## Scope
**In scope:** port the runtime probes as `omanix-hw-*` scripts and, where a probe is really a
static build-time fact, add a NixOS option instead. Cover:
`omarchy-hw-{laptop,laptop-closed,clamshell,display,fingerprint,nvidia,intel-sof,webcam}`.
**Out of scope:** acting on detection (monitor reconfiguration, driver install) — those live in
their own tickets/modules. Just the detection primitives here.

## Implementation notes
Per-item guidance (script vs option):
- **`omanix-hw-laptop-closed`** — MUST stay a runtime script (reads `/proc/acpi/button/lid/*/state`; changes at runtime).
- **`omanix-hw-clamshell`** — runtime script (`laptop-closed && external-monitors`).
- **`omanix-hw-webcam`** — runtime script (delegates to `omanix-capture-webcam-list`, Q4-05); gates webcam features.
- **`omanix-hw-display`** — runtime script; prints the most likely backlight device (heuristic gmux → amdgpu → intel → acpi_video, excluding T2 Mac Touch Bar backlight).
- **`omanix-hw-laptop`** — runtime script ok (ACPI lid switch, else DMI chassis type), but on NixOS the answer is usually known at build time; consider also exposing `omanix.hardware.isLaptop` as an override.
- **`omanix-hw-fingerprint`** — runtime probe of `/sys/bus/usb/devices` (vendor-ID allowlist + product-string match, only when no kernel driver is bound). Keep as a script (needs to work before fprintd). On NixOS, fingerprint *enablement* is `services.fprintd.enable` — the script is for conditional prompting, not setup.
- **`omanix-hw-nvidia`** — reads cached sysfs vendor `0x10de` + class `0x03*` (deliberately avoids lspci to not wake a suspended GPU). Keep as script; note NixOS users typically already set `hardware.nvidia`/`services.xserver.videoDrivers` declaratively — this is for runtime conditionals only.
- **`omanix-hw-intel-sof`** — `lspci` grep for Intel SOF audio controller. Script; consumed by Q4-03 audio tuning.
- Apply **D1** to all names. Register in `pkgs/omanix-scripts/default.nix` with deps: `coreutils`, `gnugrep`, `pciutils` (lspci, only where used), `usbutils` optional (fingerprint reads sysfs directly, no usbutils needed). Keep deps minimal — these are probes.
- These probes return exit codes for use in conditionals (like omanix's existing `hw-*` convention) — match that.

## Acceptance criteria
- [x] Scripts exist for laptop, laptop-closed, clamshell, display, fingerprint, nvidia, intel-sof, webcam, renamed per D1, registered in `default.nix`. (Plus emitters `omanix-battery-status`, `omanix-system-stats` — see scope note.)
- [ ] Each returns a correct exit code / string on the dev machine (document expected output per host in the PR). *(runtime-only; verify on real build.)*
- [x] The doc/PR explicitly states, per probe, whether it is a runtime script or backed by a NixOS option, and why. (`laptop` is a runtime script with an `omanix.hardware.isLaptop` override; all others are runtime-only — they read state that changes at runtime or that Nix has no build-time equivalent for.)
- [x] `omanix-hw-webcam` correctly defers to `omanix-capture-webcam-list`, with a `/sys/class/video4linux` fallback + `TODO(Q4-05)` until Q4-05 merges.

## Testing
- `nix build .#omanix-scripts` succeeds.
- Run each probe on the dev host: `omanix-hw-laptop; echo $?` etc. — confirm exit codes match reality (laptop vs desktop).
- `omanix-hw-laptop-closed` flips correctly when the lid is opened/closed (if a laptop).
- `nix flake check` passes.

## References
- omarchy: `bin/omarchy-hw-{laptop,laptop-closed,clamshell,display,fingerprint,nvidia,intel-sof,webcam}`
- omanix: `pkgs/omanix-scripts/default.nix`, `pkgs/omanix-scripts/src/`, `modules/nixos/default.nix` (for any `omanix.hardware.*` option)
