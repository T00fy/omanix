# Q1-13: polkit / media / network / bluetooth / tray / power plugins

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q1-04
- **Blocks:** Q3-01, Q3-02, Q3-03
- **Size:** L

## Context
Omarchy 4.0.2 folds the remaining system-integration surfaces into shell plugins backed by
Quickshell service modules. This ticket brings up the batch of "system service" plugins that
replace omanix's scattered daemons/applets:

| Plugin | Kind | Quickshell service | Supersedes in omanix |
|--------|------|--------------------|----------------------|
| `omanix.polkit` | overlay/agent | `Quickshell.Services.Polkit` | `hyprpolkitagent` autostart |
| `omanix.media` | service + bar-widget | `Quickshell.Services.Mpris` | mpris module in Waybar + playerctl |
| `omanix.network` | panel | `Quickshell.Services.Networking` (+ nmcli) | networkmanagerapplet / bar network module |
| `omanix.bluetooth` | panel | `Quickshell.Services.Bluetooth` | bluetui / bar bluetooth module |
| `omanix.tray` | bar-widget | `Quickshell.Services.SystemTray` | tray module in Waybar |
| `omanix.power` | panel | `Quickshell.Services.UPower` | battery module in Waybar / battery-monitor |

Together these let the shell fully replace the Waybar + applet stack for status/interaction.

## Scope
**In scope:** vendor + enable all six plugins; confirm each loads against its Quickshell service
module and functions (see per-plugin acceptance below); ensure the bar-widget plugins (`media`,
`tray`) are placed in the default bar layout and the panels (`network`, `bluetooth`, `power`) are
summonable.
**Out of scope:** the Hyprland keybindings that summon the panels (Q3-01); removing the Waybar
modules and old autostarts (Q3-02/Q3-03); advanced network features (band toggle, QR, speedtest
— those are Q4-04 CLI helpers, though the network panel may surface them later).

## Implementation notes
- Sources (vendored by Q1-02, D1 rename `omarchy.*` → `omanix.*`):
  - polkit: `shell/plugins/polkit/{PolkitAgent.qml,PolkitModel.js,manifest.json}`
  - media: `shell/plugins/services/media/{Service.qml,MediaModel.js,BarWidget.qml,manifest.json}`
  - network: `shell/plugins/panels/network/{Panel.qml,Model.js,manifest.json}`
  - bluetooth: `shell/plugins/panels/bluetooth/{Panel.qml,Model.js,manifest.json}`
  - tray: `shell/plugins/bar/widgets/Tray.qml` (+ its `*.manifest.json`)
  - power: `shell/plugins/panels/power/{Panel.qml,Model.js,manifest.json}`
- **Q1-01 dependency:** the Quickshell build MUST include `Polkit`, `Mpris`, `Networking`,
  `Bluetooth`, `SystemTray`, `UPower`. If any is missing, that plugin will fail to load — this is
  the most likely failure mode; verify the build's enabled modules first.
- The `network`/`bluetooth` panels shell out to system tools (`nmcli`, `bluetoothctl`/bluez).
  Ensure NetworkManager and bluez are enabled in the NixOS config (omanix already enables
  bluetooth) and the tools are on PATH for the shell process.
- **omanix note:** omanix uses `wlctl` (a wifi TUI) and `bluetui` today; those become redundant
  for the panel path but this ticket does not remove them.
- polkit: only one polkit agent may run. During bring-up, the old `hyprpolkitagent` autostart is
  still present (removed in Q3-02); to test, temporarily stop it so only `omanix.polkit` handles
  a privilege prompt.
- Enablement: bar-widgets go in `shell.json` `bar.layout` sections; panels are enabled built-ins
  summoned by IPC. Match omarchy's default layout for placement.

## Acceptance criteria
- [ ] All six plugins load in the running shell without error (no missing-Quickshell-module
      failures).
- [ ] **polkit:** a privileged action (e.g. a pkexec prompt) is handled by `omanix.polkit` with a
      working password dialog; only one polkit agent is active.
- [ ] **media:** playing media (e.g. a browser/Spotify) shows in the media bar widget; play/pause
      and track info work via Mpris.
- [ ] **network:** the network panel lists Wi-Fi networks and can connect/disconnect; status
      reflects the active connection.
- [ ] **bluetooth:** the bluetooth panel lists devices and can pair/connect/disconnect.
- [ ] **tray:** SNI tray icons (e.g. from a running tray app) appear in the bar and respond to
      click/menu.
- [ ] **power:** the power panel shows battery/charge state (UPower) and any power actions render.
- [ ] `nix flake check` passes.

## Testing
- Build: `nix flake check`, `nix build .#omanix-shell`.
- Runtime (Hyprland session, laptop preferred for power/bluetooth): validate each plugin per its
  acceptance line. Summon panels via the IPC surface from Q1-04 (e.g.
  `omanix-shell shell summon omanix.network`). For polkit, run a `pkexec true` and confirm the
  shell dialog appears. For tray, launch a known SNI app.
- Confirm in the shell log that each plugin's Quickshell service module resolved (no
  `module not found` warnings).

## References
- omarchy: `shell/plugins/polkit/`, `shell/plugins/services/media/`,
  `shell/plugins/panels/network/`, `shell/plugins/panels/bluetooth/`,
  `shell/plugins/bar/widgets/Tray.qml`, `shell/plugins/panels/power/`, `docs/omarchy-shell.md`
- omanix: `modules/home-manager/ui/waybar.nix` (mpris/network/bluetooth/tray/battery modules),
  `modules/home-manager/desktop/hyprland/autostart.nix` (line ~33, hyprpolkitagent),
  Q1-01 Quickshell module list, seeded `shell.json` from Q1-03
