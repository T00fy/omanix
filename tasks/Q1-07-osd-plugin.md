# Q1-07: OSD plugin + `omanix-osd`

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q1-04
- **Blocks:** Q3-01, Q3-02, Q3-03
- **Size:** M

## Context
Omarchy 4.0.2 replaced SwayOSD with the `omarchy.osd` Quickshell plugin plus a thin
`bin/omarchy-osd` CLI that triggers the on-screen display. It shows volume/brightness/media
overlays. This supersedes omanix's SwayOSD module (`modules/home-manager/ui/swayosd.nix`),
whose `swayosd-server` is autostarted and whose `swayosd-client` is driven by media-key
bindings. Under D1 the plugin id is `omanix.osd` and the CLI is `omanix-osd`.

## Scope
**In scope:** the `omanix.osd` plugin loading; the `omanix-osd` CLI (ported from
`bin/omarchy-osd`) that shows volume/brightness/mute overlays via the shell IPC; verifying
overlays render on volume/brightness changes.
**Out of scope:** the audio volume commands that *call* the OSD (`omanix-audio-output-volume`
lives in Q4-03; this ticket only needs a minimal trigger to prove the OSD); rebinding media
keys in Hyprland (Q3-01); removing the SwayOSD module (Q3-03); OSD theming (Q2-02).

## Implementation notes
- Source: `shell/plugins/osd/` — `Osd.qml`, `OsdModel.js`, `manifest.json`; CLI `bin/omarchy-osd`
  (small, ~40 lines). Vendor via Q1-02 / package the CLI in `pkgs/omanix-scripts` with the D1
  rename applied.
- `omanix-osd` calls the shell over IPC (`omanix-shell osd ...` or the plugin's IPC target).
  Confirm the target name after the D1 rename (`omanix.osd` / `osd`).
- Omanix currently binds volume/brightness/playerctl media keys to `swayosd-client` in
  `desktop/hyprland/bindings.nix`. Those binds are rewired to `omanix-osd` / audio commands in
  Q3-01; this ticket only provides the working `omanix-osd` command.
- **D1:** plugin id/IPC target and command name renamed via Q0-03 patch.

## Acceptance criteria
- [ ] `omanix.osd` plugin loads (`omanix-shell shell listPlugins`).
- [ ] `omanix-osd` is on PATH (from `pkgs/omanix-scripts`) and, when invoked, shows an OSD overlay in the running shell.
- [ ] A volume or brightness change (via `wpctl`/`brightnessctl` + `omanix-osd`) displays the corresponding overlay with the current level.
- [ ] `nix flake check` passes; `pkgs/omanix-scripts` builds with `omanix-osd` present.

## Testing
- Build: `nix build .#omanix-scripts` (or the attr that exposes scripts); `omanix-osd --help`/no-arg runs without error.
- Runtime (Hyprland session, shell running, swayosd NOT running): trigger `omanix-osd` for volume up/down → overlay appears and dismisses after timeout.
- Confirm no `swayosd-server` process is required.

## References
- omarchy: `shell/plugins/osd/` (`Osd.qml`, `OsdModel.js`, `manifest.json`), `bin/omarchy-osd`
- omanix: `modules/home-manager/ui/swayosd.nix` (superseded), `modules/home-manager/desktop/hyprland/bindings.nix` (media keys, rewired later), `pkgs/omanix-scripts/`
