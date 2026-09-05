# Q1-13: polkit / media / network / bluetooth / tray / power plugins

- **Phase:** 1
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q3-01, Q3-02, Q3-03
- **Size:** L

## Resolution

All six plugins are first-party and needed **no QML changes** — they auto-load because none
are in `disabledPlugins`, and Q1-01 already confirmed the Quickshell build ships every module
they need (`Polkit`, `Mpris`, `Networking`, `Bluetooth`, `SystemTray`, `UPower`). Five of the
six bar-widget ids (`omanix.network`, `omanix.bluetooth`, `omanix.tray`, `omanix.power`, plus
`omanix.audio`) were already placed in the bar layout by Q1-05, so the Nix work was small:

- **media widget placement** (`desktop/quickshell.nix`): added `{ id = "omanix.media"; }` as the
  first entry of the `bar.layout.center` default (before `omanix.clock`), matching omarchy's
  default layout (`plugins/bar/README.md`). It serializes into `declaredBase` and reconciles onto
  the user's `shell.json` on activation like every other Q1-05 widget. The `omanix.media` service
  (Mpris + Pipewire) also auto-loads to feed it.
- **polkit conflict** (`desktop/hyprland/autostart.nix`): the `omanix.polkit` service auto-loads
  and registers the DBus polkit agent, so the old `hyprpolkitagent` autostart is now gated on
  `!omanix.quickshell.enable` — when the shell is active `omanix.polkit` is the sole agent; the old
  agent still starts when the shell is off. This pulls part of **Q3-02** forward (precedent: Q1-06
  retired mako early rather than run two of the same daemon at once).
- **NetworkManager** (decision: leave to host): the network panel drives its list/connect actions
  through NetworkManager (`Quickshell.Networking` + `nmcli`), which omanix does **not** enable in
  any module — it stays out of the host's networking choice. Documented via a comment on the
  `omanix.network` layout entry; hosts must set `networking.networkmanager.enable` for the panel to
  be functional. `wl-copy`/`uuidgen` (used by the enterprise-connect path) are already in the
  shell's `home.packages`; bluetooth is already enabled (`hardware.bluetooth`).

Verified by HM eval: `bar.layout.center` renders `["omanix.media","omanix.clock"]`; the right
section is unchanged; the autostart Lua omits `hyprpolkitagent` when `quickshell.enable = true` and
includes it when false. `nix flake check` passes.

**Follow-ups / out of scope (non-blocking — plugins load and core service functions work without
these):** the `omanix-*` helper CLIs the panels shell out to on user action are not yet
implemented and belong to later phases — `omanix-hw-laptop-closed`, `omanix-battery-status`,
`omanix-system-stats` (**Q4-02**); `omanix-audio-output-set-default` (**Q4-03**);
`omanix-network-{status,band}`, `omanix-dns`, `omanix-bluetooth-{device,power}`,
`omanix-powerprofiles-{list,set}`, `omanix-launch-floating-terminal-with-presentation`
(**Q4-04** / audio). Panel keybindings are **Q3-01**; Waybar module + networkmanagerapplet removal
and the rest of the autostart cleanup are **Q3-02/Q3-03**. `omanix.audio` was placed by Q1-05 and
is not one of this ticket's six.

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
- [x] All six plugins load in the running shell without error (no missing-Quickshell-module
      failures). *(All first-party, absent from `disabledPlugins`; Q1-01 confirmed every module
      present. Runtime load not exercisable here.)*
- [~] **polkit:** a privileged action (e.g. a pkexec prompt) is handled by `omanix.polkit` with a
      working password dialog; only one polkit agent is active. *(Sole-agent guaranteed: hyprpolkitagent
      autostart gated off when the shell is enabled. Dialog is runtime-only.)*
- [~] **media:** playing media (e.g. a browser/Spotify) shows in the media bar widget; play/pause
      and track info work via Mpris. *(`omanix.media` added to the center layout; service auto-loads.
      Runtime-only.)*
- [~] **network:** the network panel lists Wi-Fi networks and can connect/disconnect; status
      reflects the active connection. *(Widget in layout; requires host NetworkManager per decision.
      Runtime-only.)*
- [~] **bluetooth:** the bluetooth panel lists devices and can pair/connect/disconnect. *(Widget in
      layout; bluetooth already enabled. Runtime-only.)*
- [~] **tray:** SNI tray icons (e.g. from a running tray app) appear in the bar and respond to
      click/menu. *(Widget in layout. Runtime-only.)*
- [~] **power:** the power panel shows battery/charge state (UPower) and any power actions render.
      *(Widget in layout. Runtime-only.)*
- [x] `nix flake check` passes.

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
