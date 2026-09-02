# Q0-05: Shell external-command contract & plugin scope

- **Phase:** 0
- **Status:** todo
- **Depends on:** Q0-01
- **Blocks:** Q0-03, Q1-03, Q1-05, Q1-08, Q1-13, Q3-01, Q3-02, Q4-04, Q4-07, Q5-01
- **Size:** M

## Context
The vendored Quickshell QML desktop is a **thin caller**: at runtime it shells out to a fixed set
of external commands (recon of `shell/` found **61 distinct `omarchy-*` commands**, ~25 generic
tools, and a few in-tree helpers). After the D1 rename (Q0-03) every `omarchy-foo` call becomes
`omanix-foo` — so if `omanix-foo` does not exist, the shell throws a runtime error the moment a
user opens the panel/widget that calls it. **omanix does not vendor omarchy's `bin/` scripts;** it
owns the callees (clean omanix scripts or Nix modules).

This ticket pins that command surface as an **interface contract** and records a **disposition for
every command**: *implement* (clean runtime action/info), *ephemeral overlay* (declared config is
source of truth, runtime switch reverts on rebuild — D2 pattern), or *out of scope → disable the
plugin/menu-entry so the shell never calls it*. It is the checklist that guarantees nothing
dangles at runtime, and the source of the `disabledPlugins` / removed-menu-entry set that Q1-03
seeds.

**Guiding principle (ratified):** *runtime switching of something Nix declares defaults to OUT OF
SCOPE* — declare it in the flake, disable the shell's picker. Keep a runtime switch only as a
D2-style ephemeral overlay where instant switching has real standalone UX value (theme, monitor
scaling, power profile).

## Scope
**In scope:** the authoritative disposition table below; the list of plugins/panels/menu-entries
to disable in the seeded `shell.json`; flagging the two behavioral landmines the D1 sed-rename
cannot fix; and the per-command → implementing-ticket map so no KEEP command is orphaned.
**Out of scope:** implementing the individual commands (their own tickets); the rename mechanism
itself (Q0-03).

## Disposition of the 61 `omarchy-*` commands

### A. KEEP — inherently runtime (implement as clean `omanix-*`)
Map each to its implementing ticket; none may be left unimplemented if its plugin is enabled.

- **Audio:** `audio-input-set-default`, `audio-output-set-default`, `audio-output-sink`, `audio-sink-availability` → Q4-03 / Q1-13 (audio panel).
- **Bluetooth:** `bluetooth-device`, `bluetooth-power` → Q1-13.
- **Brightness:** `brightness-display`, `brightness-keyboard` → Q1-07 (OSD) / Q1-13.
- **Clipboard:** `clipboard-open`, `clipboard-paste-file`, `clipboard-paste-text` → Q1-09 / Q3-04.
- **Capture:** `capture-screenrecording` → Q4-05 (+ the ScreenRecording indicator).
- **Notifications:** `notification-send` → Q1-06 (omanix already has this script).
- **Lock/idle:** `system-lock`, `system-wake`, `launch-screensaver`, `hyprland-session-locked` → Q1-11 / Q1-12.
- **Network (info + connect):** `network-band`, `network-qr`, `network-password`, `network-status`, `network-speedtest` → Q4-04.
- **Power/battery:** `battery-status`, `battery-low`, `system-stats`, `powerprofiles-list`, `powerprofiles-set` → Q1-13 (power panel). *(`powerprofiles-*` is a genuine runtime mode toggle, not static config — KEEP.)*
- **Agents:** `agent`, `agent-usage-update`, `default-agent` → Q5-01 / Q5-02. *(`default-agent` is the declarative-option + ephemeral-picker case already defined in Q5-01.)*
- **Theme/bg:** `theme-set`, `theme-switcher`, `theme-bg-set`, `theme-bg-switcher` → Q2-04 / Q2-05 (D2 ephemeral).
- **Launchers/IPC:** `shell`, `menu`, `launch-browser`, `launch-floating-terminal-with-presentation` → Q1-04 / Q1-08 / existing omanix `launch-*`. *(`launch-browser` merely opens the default browser — distinct from the cut `default-browser` setter; KEEP.)*
- **Hyprland:** `hyprland-focus-app` → Q3-01 / Q1-06.
- **Misc:** `menu-emoji-insert` → Q1-09; `tailscale-send` → Q4-07; `bar-text-color` → Q1-14.

### B. EPHEMERAL OVERLAY (D2 pattern — declared config wins on rebuild)
- **Monitor/display:** `hyprland-monitor-scaling`, `display-text-size`, `monitor-state` → live-adjust scale/text-size when docking/plugging an external display; declared Hyprland `monitors` config is source of truth and reverts on rebuild. Needs a small ticket or fold into the Q1-13 monitor panel; wire persistence per Q1-03 § *Declarative reconcile contract*.

### C. OUT OF SCOPE — disable the plugin/panel/menu-entry (shell must not call these)
Runtime switching of Nix-declared config, or Arch/package/update coupling.

- **Declared-config pickers (ratified CUT):** `default-browser`, `default-editor`, `default-terminal`, `menu-timezone`, `dns`. Users declare browser/editor/terminal via `xdg.mimeApps`/session vars, `time.timeZone`, and `networking.*`. **Disable** the Setup › Defaults browser/editor/terminal entries, the timezone picker, and the **DNS panel**.
- **Update / package / channel (already out of scope):** `channel-current`, `update`, `update-available`, `remove-launcher-entry`, `pkg-present`, `pkg-missing`. **Disable** the SystemUpdate/pending-updates widget and the pacman-backed menu guards (see landmine 1). *(Ratified: no pending-updates indicator.)*
- **Night Light (ratified CUT):** the NightLight bar indicator/toggle (`hyprsunset`-backed). **Disable** the widget; drop `hyprsunset` from the required PATH set if nothing else uses it. *(User does not want night light.)*
- **Dropbox panel (ratified CUT for now):** `dropbox-cli` + in-tree `status.py`. **Disable** the Dropbox panel and add to `disabledPlugins`. *(User: don't care right now.)*

### Feature-inclusion decisions (per feature)
Runtime features with no omanix home yet. For each: *implement the callee* or *disable the
plugin/widget* (disabled features are added to the seeded `disabledPlugins`).

**Resolved:**
- Dropbox panel → **DISABLE** (see section C).

**Still OPEN (decide before enabling their plugins; recommend disabling unless wanted):**
- `weather-status`, `weather-location` (weather widget/panel)
- `reminder` (reminders)
- `voxtype-status`, `voxtype-config` (dictation)
- `disk-speedtest` (disk benchmark panel)

### Non-command feature dispositions (reviewed against the Quattro feature tour)
These aren't part of the 61-command shell surface (they're menu entries, standalone apps, or
already-shipped omanix features), but were reviewed and ruled on so nothing is silently assumed:

- **Already in omanix — no work, do not re-scope:** LocalSend file sharing (`omanix-cmd-share.sh`);
  Moonlight/Sunshine game streaming (`modules/nixos/sunshine.nix`) — so **cloud gaming
  (GeForce NOW/Xbox) stays CUT**, per Q4-08; the BBS/TTFX screensaver (`pkgs/omanix-screensaver/`);
  the **keybindings menu** (`omanix-menu-keybindings.sh`, built dynamically from `hyprctl -j binds`
  — automatic, no maintenance; only needs the walker→shell rewire the rest of the menu gets).
- **CUT (ratified):** Web App Creator (frameless PWA wrapper + webapp menu entries); Ether theme
  generator; Compose-key/XCompose sequences (tried before, not worth it); direct config-editing
  from the menu (conflicts with the declarative model — the Style/Learn "edit config" entries are
  dropped; the Omarchy Manual link is repointed to the maintained GitHub manual); VS Code theme
  target (not used); multiple named lock-screen styles.
- **OUT OF SCOPE for now (revisit later):** TUI floating wrappers (btop/lazydocker containers);
  Windows VM integration; the bespoke built-in apps (Omawrite, Video Trimmer, Calculator, Kampa).
- **ADD (new work):** image transcoding (image → compressed JPEG → clipboard) → folded into Q4-05;
  custom system branding / About screen (neofetch-style summary + logo→ANSI, feeding the existing
  screensaver) → new ticket **Q4-12**.

## Landmines the D1 rename (Q0-03) cannot fix — needs real handling
1. **Embedded `pacman -Qq/-Qi/-Q` guard batch** in `shell/plugins/menu/MenuModel.js` (`guardHelpers()`, ~lines 420-437, run via `Menu.qml`). This is Arch bash *inside the QML tree*. The menu uses it to show/hide entries by installed-package presence. On Nix, "is package X installed" is answered differently — reimplement the guard (e.g. `command -v`, or drop package guards for cut entries) in Q1-08. The sed rename will not repair it.
2. **`pkexec tailscale set --operator`** in `shell/plugins/panels/tailscale/Service.qml` (~line 353). Privilege escalation baked into QML. Reframe in Q4-07 (declare the operator via `services.tailscale`/module option, or gate the panel action).

## Generic tools (bucket B) — must be on the shell's PATH
`bash`, `hyprctl`, `hyprsunset`, `fc-match`, `xkbcli`, `find`, `mkdir`, `readlink`, `pgrep`,
`pkill`, `setpriv`, `setsid`, `wl-paste`, `wl-copy`, `uwsm-app`, `gtk-launch`, `uuidgen`, `nmcli`,
`curl`, `python3`, `dropbox-cli`, `nautilus`, `tailscale`, `which`, `pkexec`. Provide these via the
shell's wrapped PATH (Q1-02/Q1-13), not ambient session PATH.

## Acceptance criteria
- [ ] This ticket lists every `omarchy-*` command the vendored shell invokes, each with a disposition (KEEP+ticket / OVERLAY / OUT-OF-SCOPE) and no gaps.
- [ ] The set of plugins/panels/menu-entries to disable is enumerated and handed to Q1-03 (seeded `disabledPlugins` / removed menu entries) so the shell never calls a cut command.
- [ ] The two landmines are assigned (guard batch → Q1-08; `pkexec` tailscale → Q4-07) and Q0-03's scope notes it must not be expected to fix them.
- [ ] The feature-inclusion open items have a recorded decision (implement or disable) before their plugins are enabled.
- [ ] A verification step exists (grep the vendored+renamed tree for its command surface; assert every enabled-plugin command has an `omanix-*` implementer or a generic-tool provider).

## Testing
```bash
# After Q1-02 vendors + renames the tree, enumerate the actual runtime command surface:
grep -rhoE 'omanix-[a-z0-9-]+' /path/to/store/omanix-shell/share/omanix/shell | sort -u
# Every result must be either an omanix-scripts binary or an intentionally-disabled plugin's command.
```
- Cross-check the grep output against the disposition table: no command is both invoked-by-an-enabled-plugin and unimplemented.
- Runtime: open each enabled panel/widget in a Hyprland session; confirm no "command not found" in `journalctl --user` / shell stderr. Confirm cut panels (DNS, defaults pickers, SystemUpdate) are absent from the UI.

## References
- omarchy: `shell/` tree (command call sites listed in the disposition table), `bin/omarchy-*` (callee sources), `shell/plugins/menu/MenuModel.js` (guard batch), `shell/plugins/panels/tailscale/Service.qml` (pkexec)
- omanix: `pkgs/omanix-scripts/`, seeded `shell.json` (Q1-03), Q0-03 (rename), and the per-command implementing tickets referenced above
