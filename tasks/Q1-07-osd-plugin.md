# Q1-07: OSD plugin + `omanix-osd`

- **Phase:** 1
- **Status:** done
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
- [~] `omanix.osd` plugin loads (`omanix-shell shell listPlugins`). *(Plugin vendored + D1-renamed with `keepLoaded: true`, not in `disabledPlugins` — loads by default. Runtime listing needs a live session.)*
- [~] `omanix-osd` is on PATH (from `pkgs/omanix-scripts`) and, when invoked, shows an OSD overlay in the running shell. *(Shipped: `omanix-osd` builds the JSON payload and calls `omanix-shell -q osd show`. Overlay render is runtime-only.)*
- [~] A volume or brightness change (via `wpctl`/`brightnessctl` + `omanix-osd`) displays the corresponding overlay with the current level. *(Runtime-only; producers are Q4-03.)*
- [x] `nix flake check` passes; `pkgs/omanix-scripts` builds with `omanix-osd` present.

## Implementation outcome
No QML changes — the vendored `omanix.osd` plugin already loads (`keepLoaded: true`). Ported
`bin/omarchy-osd` → `pkgs/omanix-scripts/src/omanix-osd.sh` (D1 rename; upstream's `omarchy osd
--help` dispatcher call replaced with an inline `usage()` since omanix has no `omanix`
dispatcher; `omanix:summary/args/examples` headers kept). Registered in
`pkgs/omanix-scripts/default.nix` (`deps = [bash coreutils jq]`, `selfPath = true` to reach the
sibling `omanix-shell`). It forwards `osd show '<json>'` best-effort (`-q`), so a down shell
no-ops (exit 0). No new option surface; no HM-module change (package already in `home.packages`).

## Testing
- Build: `nix build .#omanix-scripts` (or the attr that exposes scripts); `omanix-osd --help`/no-arg runs without error.
- Runtime (Hyprland session, shell running, swayosd NOT running): trigger `omanix-osd` for volume up/down → overlay appears and dismisses after timeout.
- Confirm no `swayosd-server` process is required.

## References
- omarchy: `shell/plugins/osd/` (`Osd.qml`, `OsdModel.js`, `manifest.json`), `bin/omarchy-osd`
- omanix: `modules/home-manager/ui/swayosd.nix` (superseded), `modules/home-manager/desktop/hyprland/bindings.nix` (media keys, rewired later), `pkgs/omanix-scripts/`
