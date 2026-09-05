# Q0-05: Shell external-command contract & plugin scope

- **Phase:** 0
- **Status:** done
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
- **Launcher:** `remove-launcher-entry` → Q1-08 / Q1-03. *(Recategorized from the update/package cut: verified as the launcher's hide-an-app action at `services/AppLibrary.qml:91`, NOT update-related. Implement as a user-side hide that appends to the `launcher.hides` file the shell reads at `$OMANIX_PATH/shell/defaults/launcher.hides` — the runtime write goes to `~/.config/omanix/…`, keeping the store copy declarative. Must NOT be disabled or the launcher context action dangles.)*

### B. EPHEMERAL OVERLAY (D2 pattern — declared config wins on rebuild)
- **Monitor/display:** `hyprland-monitor-scaling`, `display-text-size`, `monitor-state` → live-adjust scale/text-size when docking/plugging an external display; declared Hyprland `monitors` config is source of truth and reverts on rebuild. Needs a small ticket or fold into the Q1-13 monitor panel; wire persistence per Q1-03 § *Declarative reconcile contract*.

### C. OUT OF SCOPE — disable the plugin/panel/menu-entry (shell must not call these)
Runtime switching of Nix-declared config, or Arch/package/update coupling.

- **Declared-config pickers (ratified CUT):** `default-browser`, `default-editor`, `default-terminal`, `menu-timezone`, `dns`, `font-current`, `font-list`, `font-set`. Users declare browser/editor/terminal via `xdg.mimeApps`/session vars, `time.timeZone`, `networking.*`, and **fonts** via `fonts.*` / `fontconfig`. **Disable** the Setup › Defaults browser/editor/terminal entries, the timezone picker, the **font picker** menu entry, and the **DNS action**. *(Font picker added on verification: the `omanix-font-{current,list,set}` menu action at `plugins/menu/Menu.qml:271,274` was missing from the original table; the shell just follows the fontconfig alias `omanix-font-set` writes — `Commons/Style.qml:266`, `plugins/bar/Bar.qml:60` — so declaring the font is sufficient and the runtime picker is cut per D4.)* *(`dns` is a button inside the network panel, not a standalone plugin — remove the DNS action in `plugins/panels/network/Panel.qml:662` in Q1-13; likewise the timezone picker is a clock-widget middle-click, `plugins/panels/clock/BarWidget.qml:155`.)*
- **Update / package / channel (already out of scope):** `channel-current`, `update`, `update-available`, `pkg-present`, `pkg-missing`. **Disable** the SystemUpdate/pending-updates widget and the pacman-backed menu guards (see landmine 1). *(Ratified: no pending-updates indicator.)* *(`pkg-present`/`pkg-missing` are not standalone binaries — they are bash functions defined by the `guardHelpers()` prelude; see landmine 1.)*
- **Night Light (ratified CUT):** the NightLight bar indicator/toggle (`hyprsunset`-backed). **Disable** the widget; drop `hyprsunset` from the required PATH set if nothing else uses it. *(User does not want night light.)*
- **Dropbox panel (ratified CUT for now):** `dropbox-cli` + in-tree `status.py`. **Disable** the Dropbox panel and add to `disabledPlugins`. *(User: don't care right now.)*

### Feature-inclusion decisions (per feature)
Runtime features with no omanix home yet. For each: *implement the callee* or *disable the
plugin/widget* (disabled features are added to the seeded `disabledPlugins`).

**Resolved:**
- Dropbox panel → **DISABLE** (see section C).
- **Weather** (`weather-status`, `weather-location`; plugin `omanix.weather`) → **KEEP**. Implement
  `omanix-weather-status` + `omanix-weather-location` (needs a weather source + location; network).
  Implementing ticket TBD — fold into the bar-widget work (Q1-05/Q1-13) or a small dedicated ticket.
- **Reminders** (`reminder`; plugin `omanix.reminders` + `plugins/bar/indicators/Reminder.qml`) →
  **KEEP**. Implement `omanix-reminder` (self-contained; also uses `omanix-notification-send` → Q1-06).
  Implementing ticket TBD — fold into Q1-05/Q1-13 or a small dedicated ticket.
- **Disk speedtest** (`disk-speedtest`; plugin `omanix.disk-speedtest`) → **DISABLE** → `disabledPlugins`.
- **Dictation / voxtype** (`voxtype-status`, `voxtype-config`; `plugins/bar/indicators/Dictation.qml`)
  → **DISABLE**. No voxtype dictation backend is packaged; omit the Dictation bar indicator from the
  layout so `omanix-voxtype-*` is never called. (Indicator, not a standalone plugin id — layout omission.)

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

## Seeded `shell.json` scope — the artifact Q1-03 consumes

This is the machine-usable output of the disposition table. Three distinct mechanisms turn a
feature off (verified against `services/PluginRegistry.qml:110-144`): **(a)** `disabledPlugins[]`
(the opt-out kill-switch for first-party *services / panels / overlays* — enabled-by-default
otherwise); **(b)** *omission from `bar.layout`* for bar **widgets/indicators** (they are enabled by
being listed, so simply don't list them — `disabledPlugins` does not apply to layout entries);
**(c)** *non-emission from the Nix-generated `defaults/omanix-menu.jsonc`* for menu entries (cut =
don't write the entry). Use the exact plugin ids below verbatim.

### (a) `disabledPlugins` — plugin ids to seed
```json
"disabledPlugins": ["omanix.dropbox", "omanix.nightlight", "omanix.disk-speedtest"]
```
- `omanix.dropbox` — Dropbox panel, ratified CUT.
- `omanix.nightlight` — Night Light service, ratified CUT (also drop `hyprsunset` from the shell's
  required PATH set if nothing else uses it).
- `omanix.disk-speedtest` — disk benchmark panel, CUT (user decision).

### (b) Bar-layout omissions — widgets/indicators NOT to list in `bar.layout`
These are `bar/widgets/*` or `bar/indicators/*`, not standalone plugin ids, so they are excluded by
leaving them out of the seeded layout (not via `disabledPlugins`):
- SystemUpdate widget (`plugins/bar/widgets/SystemUpdate.qml`) — no pending-updates indicator.
- NightLight indicator (`plugins/services/nightlight` bar indicator) — CUT.
- Dictation indicator (`plugins/bar/indicators/Dictation.qml`) — voxtype CUT.

### (c) Menu-jsonc entries NOT to emit
When Q1-08 generates `defaults/omanix-menu.jsonc`, do not emit:
- Setup › Defaults browser / editor / terminal (`default-browser`, `default-editor`, `default-terminal`).
- Timezone picker (`menu-timezone`).
- Font picker (`font-current` / `font-list` / `font-set`).
- Any entry whose `when:`/`checked:` uses `omanix-pkg-present` / `omanix-pkg-missing` or the
  update/channel commands (`channel-current`, `update`, `update-available`).
- Ratified content cuts: Web App Creator + webapp entries, Ether theme generator, Compose-key /
  XCompose, direct "edit config" entries (Style/Learn), VS Code theme target. Repoint the Omarchy
  Manual link to the maintained GitHub manual.

### Sub-panel code edits (NOT config — a QML change in the owning plugin)
Reachable only from inside a KEPT panel, so no plugin/layout/menu toggle removes them:
- DNS action inside the network panel (`omanix-dns`, `plugins/panels/network/Panel.qml:662`) → remove in **Q1-13**.
- `pkexec tailscale` inside the tailscale panel (`Service.qml:353`) → reframe in **Q4-07** (landmine 2).

### Reconciliation with Q0-03 (rename) — ordering note
Q0-03 was authored/committed **before** this ticket (the tracker's `Q0-03 depends on Q0-05` edge was
satisfied out of order). This is safe because Q0-03's `apply_rename()` strips **every**
`$OMANIX_PATH/bin/` prefix generically rather than from a curated list — its effective "prefix-strip
set" is therefore a **superset** of every command in this contract. The reconciliation the tracker
requires ("the two must agree") holds by construction; the Testing grep below proves no command
escapes it.

## Landmines the D1 rename (Q0-03) cannot fix — needs real handling
1. **Embedded `pacman -Qq/-Qi/-Q` guard batch** in `plugins/menu/MenuModel.js` (`guardHelpers()` at ~line 410; comments/body span ~lines 399-420; its prelude is wired into the guard batch at `plugins/menu/Menu.qml:432`, run via `guardProc` at `Menu.qml:972`). *(Verified against the vendored tree — the original "~lines 420-437" estimate was off, and the first recon pass missed it entirely because it grepped only `.qml`/`.sh`, not `.js`.)* This is Arch bash *inside the QML tree*: the prelude runs `pacman -Qq` + `pacman -Qi` and defines the `omanix-pkg-present` / `omanix-pkg-missing` bash functions the menu's `when:`/`checked:` fields call. **Critical:** the prelude batch runs on **every menu reload regardless of which entries exist** — so on NixOS (no `pacman`) it errors even after we omit all package-guarded entries from the generated jsonc. On Nix, "is package X installed" is answered differently — reimplement/neuter the guard (e.g. `command -v`, or drop package guards) in **Q1-08**. The sed rename will not repair it.
2. **`pkexec tailscale set --operator`** in `shell/plugins/panels/tailscale/Service.qml` (~line 353). Privilege escalation baked into QML. Reframe in Q4-07 (declare the operator via `services.tailscale`/module option, or gate the panel action).

## Generic tools (bucket B) — must be on the shell's PATH
`bash`, `hyprctl`, `hyprsunset`, `fc-match`, `xkbcli`, `find`, `mkdir`, `readlink`, `pgrep`,
`pkill`, `setpriv`, `setsid`, `wl-paste`, `wl-copy`, `uwsm-app`, `gtk-launch`, `uuidgen`, `nmcli`,
`curl`, `python3`, `dropbox-cli`, `nautilus`, `tailscale`, `which`, `pkexec`. Provide these via the
shell's wrapped PATH (Q1-02/Q1-13), not ambient session PATH.

## Acceptance criteria
- [x] This ticket lists every `omarchy-*` command the vendored shell invokes, each with a disposition (KEEP+ticket / OVERLAY / OUT-OF-SCOPE) and no gaps. *(Verified against the committed renamed tree; added the missing `font-*` picker and recategorized `remove-launcher-entry`.)*
- [x] The set of plugins/panels/menu-entries to disable is enumerated and handed to Q1-03 (seeded `disabledPlugins` / removed menu entries) so the shell never calls a cut command. *(See "Seeded `shell.json` scope".)*
- [x] The two landmines are assigned (guard batch → Q1-08; `pkexec` tailscale → Q4-07) and Q0-03's scope notes it must not be expected to fix them. *(Both located in the vendored tree; landmine 1 line numbers corrected to `MenuModel.js:~399-420` + `Menu.qml:432`.)*
- [x] The feature-inclusion open items have a recorded decision (implement or disable) before their plugins are enabled. *(Weather + Reminders KEEP; disk-speedtest + dictation DISABLE.)*
- [x] A verification step exists (grep the vendored+renamed tree for its command surface; assert every enabled-plugin command has an `omanix-*` implementer or a generic-tool provider). *(See Testing.)*

## Testing
This is a decision/documentation ticket — "tests" are consistency checks. They run **now** against
the committed renamed tree (`vendor/omanix-shell/`); the store-path variant applies after Q1-02.
```bash
# 1. Enumerate the actual runtime command surface of the vendored shell:
grep -rhoE 'omanix-[a-z0-9-]+' vendor/omanix-shell | sort -u
#    (after Q1-02, same over the installed tree: .../omanix-shell/shell)
# Every result must be either a KEEP command with a named implementing ticket (→ omanix-scripts
# binary) OR reachable only from a disabled plugin / omitted bar widget / omitted menu entry.
# Note: the grep also returns non-command tokens (plugin ids like `omanix.` are dotted, but
# layer-shell namespaces / reloadableIds such as `omanix-bar`, `omanix-osd`, `omanix-notifications`
# are hyphenated) — cross-check against the "NOT invoked commands" exclusions, don't treat every
# hit as a callee.

# 2. Both landmines still present exactly where this ticket says (guards Q1-08 / Q4-07):
grep -n 'pacman' vendor/omanix-shell/plugins/menu/MenuModel.js            # → guardHelpers(), ~399-420
grep -n 'pkexec' vendor/omanix-shell/plugins/panels/tailscale/Service.qml # → :353

# 3. The disabledPlugins ids are real plugin dirs with a manifest:
for id in dropbox nightlight disk-speedtest; do
  find vendor/omanix-shell/plugins -type d -name "$id" -exec test -f '{}/manifest.json' ';' \
    -exec echo "ok: omanix.$id" ';'
done
```
- Cross-check the grep output against the disposition table: no command is both invoked-by-an-enabled-plugin and unimplemented.
- Runtime (deferred to Q1-03): open each enabled panel/widget in a Hyprland session; confirm no "command not found" in `journalctl --user` / shell stderr. Confirm cut features (DNS action, defaults/timezone/font pickers, SystemUpdate, Dropbox, NightLight, disk-speedtest, dictation) are absent from the UI. This ticket only guarantees the contract; Q1-03 exercises it.

## References
- omarchy: `shell/` tree (command call sites listed in the disposition table), `bin/omarchy-*` (callee sources), `shell/plugins/menu/MenuModel.js` (guard batch), `shell/plugins/panels/tailscale/Service.qml` (pkexec)
- omanix: `pkgs/omanix-scripts/`, seeded `shell.json` (Q1-03), Q0-03 (rename), and the per-command implementing tickets referenced above
- **Vendor doc/code drift (flag for Q1-02, out of Q0-05 scope):** the vendored docs still reference the pre-rename `config/omarchy/` & `default/omarchy/` layout while the QML uses the post-rename `config/` & `defaults/` layout — `vendor/omanix-shell/README.md:223`, `vendor/omanix-shell/plugins/README.md:48,104`, `vendor/omanix-shell/plugins/bar/README.md:12,17,94`. Reconcile when packaging (do not hand-edit the vendored tree here).
