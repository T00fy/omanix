# Porting Omanix to Omarchy 4.0.2 ("Quattro") parity

Working plan for the `quattro` branch. Omanix currently tracks Omarchy ~3.8. Omarchy
4.0.2 is a very large release (1,812 commits, ~1,978 files, +119k lines over 3.8.0). This
document is the **dependency-ordered porting plan and tracker** — not an exhaustive
changelog. It captures scope, the decisions we've made, the current state of omanix, and
the phased work.

Status legend: ⬜ not started · 🟡 in progress · ✅ done · ⏭️ intentionally skipped

---

## 1. Goal & scope

Bring omanix to feature parity with the parts of Omarchy 4.0.2 that make sense on NixOS.
Nix is its own paradigm; several 4.0.2 subsystems exist only to work around Arch's mutable
filesystem and imperative install model, and are obsoleted by the Nix store.

### In scope

- **Quickshell desktop** (the defining 4.0.2 rework) — replaces waybar/walker/mako/swayosd/hyprlock/hypridle.
- **Plugin system** for the shell.
- **Theming rework** — palette → `colors.toml` + `shell.toml`, plus palette-only targets (tmux/claude/pi/browser).
- **AI agents** — launcher, default-agent picker, usage widget, crash-watch (declarative).
- **herdr** terminal multiplexer.
- **Independent CLI helpers** — hardware detection, audio tuning, network, capture, security, tailscale taildrop, gaming, plymouth. Port à la carte.

### Out of scope (Nix obsoletes or replaces these)

- ⏭️ **Install / provisioning / channels / upgrade path** (omarchy `apply-*`, `provision-*`, `channel-*`, `upgrade-to-quattro`). Replaced by NixOS modules + flake inputs.
- ⏭️ **Migration system** (`omarchy-migrate`, `migrations/*.sh`). Imperative `$HOME`/`/etc` repair — obsoleted by declarative config. Retain only the `~/.local/state/omanix/` runtime-state layout where shell features need it.
- ⏭️ **Factory reset / `@factory` snapshots / Limine / Snapper** — NixOS has generations/rollback; reimplement via generations / disko / impermanence *only if wanted later*, not part of this effort.
- ⏭️ **pacman guard / ALPM hooks / etc-overrides / `--overwrite`** — meaningless under the Nix store.

### Already done in omanix

- ✅ **Hyprland config in Lua** (omarchy's `.conf`→`.lua` migration). Omanix already renders Hyprland config to Lua via `mkLuaInline` (`modules/home-manager/desktop/hyprland/`). Rewiring keybinds to shell IPC is an edit, not a rewrite.

---

## 2. Decisions (locked)

### D1 — Naming: rename everything to `omanix-*` (committed snapshot)

The vendored Quickshell `shell/` tree hardcodes `omarchy-*` command names, `omarchy.*`
plugin IPC ids, and reads `$OMARCHY_PATH`. We rename all of it to the omanix namespace
(`omanix-*`, `omanix.*`, `$OMANIX_PATH`).

**Vendoring model — committed in-repo snapshot, not a live input.** omanix does **not** track
omarchy as a live dependency and does not keep in sync. It takes a **one-time snapshot**: the
needed upstream source is copied into the repo under `vendor/`, the rename is applied **once at
vendor time** by a deterministic ruleset, and the renamed result is **committed** (Q0-01, Q0-03).
The build consumes the committed, already-renamed tree — no fetch, no `flake = false` source input,
no build-time patch. Reproducibility comes from git, not a lockfile. "Pinned" means the snapshot
records the exact upstream rev it came from (`vendor/PROVENANCE.md`) and the files live in git.

A `scripts/vendor-omarchy.sh` helper regenerates the snapshot from a given rev (clone → rename →
copy) purely as a **manual developer tool**. Re-syncing a newer omarchy is therefore a rare,
deliberate act: re-run the script + review the `git diff vendor/`. Because omanix owns the copy,
local hand-edits to the vendored tree are allowed (record them per Q0-01's local-edit policy).
Keep the rename patterns in one place and watch for false positives (URLs, user-facing strings,
the literal word in docs) — scope substitutions to code contexts and use UTF-8-safe `sed`.

### D2 — Theming: hybrid (declarative build + ephemeral runtime switch)

Omanix builds `colors.toml` + `shell.toml` for **all** themes into the store (preserves
build-time checks and reproducibility). The declared `omanix.theme` is the **source of
truth**: it is applied on every rebuild/restart. The shell's live `omanix-theme-set` (IPC
`applyTheme`) may switch themes at runtime as an **ephemeral overlay** — a rebuild or shell
restart reverts to the declared theme. This gives omanix runtime theme switching (which it
lacks today) without sacrificing declarativeness. Omanix's existing palette schema
(`lib/themes.nix`: `color0..color15` + semantic `background/foreground/accent/cursor/
selection`) already maps closely to omarchy's `colors.toml`, so this is an *extension* of
the current theme system, not a new engine.

### D4 — Runtime switching of declared config is out of scope (declare it instead)

The vendored shell is a thin caller: recon found it shells out to **61 distinct `omarchy-*`
commands** (+ ~25 generic tools, a few in-tree helpers). Only ~8 are genuinely Arch-coupled
(pacman/mise/`/etc`/sudo), and all fall in areas already dropped or reframed. The rest are clean
runtime actions/info. **omanix does not vendor omarchy's `bin/` scripts** — the D1 rename points
each `omarchy-foo` call at an omanix-owned `omanix-foo` (clean script or module), so their Arch
bash never comes along.

Principle: **anything Nix declares, you declare in the flake** — the shell's runtime picker for it
is *disabled*, not ported (default browser/editor/terminal, timezone, DNS). Keep a runtime switch
only as a **D2-style ephemeral overlay** where instant switching has real value (theme, monitor
scaling, power profile). The full per-command disposition (KEEP / ephemeral-overlay /
out-of-scope-disable), the disable set fed to the seeded `shell.json`, and two non-mechanical
landmines the sed-rename can't fix (embedded `pacman -Q` menu guards; `pkexec tailscale`) live in
ticket **Q0-05**.

### D3 — AI agent CLIs: declarative, no mise

Extend the existing `llm-agents` flake input (already used by `modules/home-manager/apps/
ai.nix` for claude-code + opencode). No mise. Fewer agents available than upstream's ~15,
but pure and Nix-idiomatic. The agent *abstraction* (default-agent picker, launcher, usage
widget) is ported; the *provisioning* mechanism (mise wrappers) is not.

### D5 — `OMANIX_PATH`: decompose, no synthetic root (refines D1, D4)

The vendored shell reads **one** env var, `OMARCHY_PATH` (→ `OMANIX_PATH`), and treats it as a
*checkout root*, deriving everything as a sibling of `shell/` (`vendor/omanix-shell/shell.qml:27-31`:
`shellPath = omarchyPath + "/shell"`, `defaultsPath = omarchyPath + "/config/omarchy/shell.json"`,
plus `omarchyPath + "/bin/omarchy-*"` and `.../default/omarchy/*` across ~13 QML files). Upstream is
one on-disk checkout where those siblings exist; our Q0-01 snapshot vendored **only** `shell/`, and
Nix has no natural "project root."

We do **not** reconstruct a synthetic multi-dir root. `OMANIX_PATH` points at the shell **code**
package only; out-of-tree references are repointed to Nix-native locations. The contract:

1. **Resolves to:** the store path of the `pkgs/omanix-shell` package, with the vendored (Q0-03-renamed)
   QML tree installed at `$out/shell/`. `OMANIX_PATH = ${pkgs.omanix-shell}`; launched with
   `quickshell -n -p $OMANIX_PATH/shell`. Nothing synthetic (`config/`/`default/`/`bin/`) is glued
   alongside to mimic an Omarchy checkout.
2. **Exported via** the Hyprland `env` directive in `modules/home-manager/desktop/hyprland/envs.nix`
   (`{ _args = [ "OMANIX_PATH" "${pkgs.omanix-shell}" ]; }`) **plus** the
   `dbus-update-activation-environment` allowlist in `autostart.nix` — explicitly **not** uwsm, which
   omanix disables (`modules/nixos/hyprland.nix`: `programs.hyprland.withUWSM = false`).
3. **In-tree assets — unchanged**, resolved via `$OMANIX_PATH/shell/...`: `plugins/`, `emojis.json`,
   in-tree `.sh` helpers (`clipboard/capture.sh`, `image-picker/list.sh`, `services/hidden-entries.sh`),
   agent SVGs (QML-relative via `Qt.resolvedUrl`).
4. **Out-of-tree references — decomposed** (implemented by Q0-03/Q0-05):
   - `$OMANIX_PATH/bin/omanix-*` → **bare command names on PATH** (scripts ship via `pkgs.omanix-scripts`
     in `home.packages`; consistent with D4).
   - `$OMANIX_PATH/config/omanix/shell.json` (`defaultsPath`) and
     `$OMANIX_PATH/default/omanix/{omanix-menu.jsonc,launcher.hides}` → **Nix-generated files** at
     explicit locations (not faked repo-root siblings). `shell.qml`'s `builtinShellConfig` fallback
     covers a missing `defaultsPath`.
5. **User config stays separate:** `~/.config/omanix/shell.json` is user-mutable/IPC-written — seeded by
   activation **copy**, never symlinked (R3). Unaffected by `OMANIX_PATH`.

**Consequence:** Q0-03's rename is no longer pure token-substitution — it also performs the structural
path rewrites in (4). See the Q0-03 and Phase 1 bullets below.

### D6 — Namespace: shell plugin ids vs Nix options (avoid conflation)

Two `omanix.*` namespaces coexist and must not be confused:

- **Shell plugin ids / IPC targets** — `omanix.<component>` (`omanix.bar`, `omanix.menu`,
  `omanix.notifications`, `omanix.osd`, `omanix.clipboard`, `omanix.background`, `omanix.lock`,
  `omanix.idle`, …). These come from the D1 rename of the vendored QML tree; they are what
  `omanix-shell shell listPlugins` reports and what IPC calls address. They are **immutable** — do
  not rename them. The `omanix.<x>` entries in the §3 component table below are these plugin ids.
- **Nix Home-Manager options** that *configure* a shell component nest under
  **`omanix.quickshell.<component>.*`** (e.g. `omanix.quickshell.bar.{position,transparent,layout,…}`),
  consistent with Q1-03's `omanix.quickshell.*` shell namespace (chosen to avoid the pre-existing
  `omanix.shell` zsh collision). New Phase-1/2 component tickets follow this when they add options.

**Legacy exceptions (predate the shell):** `omanix.waybar.*` and `omanix.idle.*`
(`modules/home-manager/desktop/hypridle.nix`) are top-level option namespaces from the old stack.
Whether idle migrates to `omanix.quickshell.idle.*` or keeps `omanix.idle.*` for back-compat is
**Q1-12's** call — recorded here so it is a known decision, not a silent contradiction.

---

## 3. Current omanix baseline (what we're changing)

Modules-only flake (`omanix.*` options; consumed by the user's own flake — no hosts).

| Concern | Omanix today | Omarchy 4.0.2 target |
|---|---|---|
| Bar | Waybar (`ui/waybar.nix`) | `omanix.bar` (Quickshell plugin) |
| Launcher / menu | Walker + Elephant (`ui/walker.nix`, `ui/elephant.nix`) + bash `omanix-menu.sh` | `omanix.menu` (launcher + app search + hierarchical menu) |
| Notifications | Mako (`ui/mako.nix`) | `omanix.notifications` (history + avatars) |
| OSD | SwayOSD (`ui/swayosd.nix`) | `omanix.osd` |
| Lock | Hyprlock (`desktop/hyprlock.nix`) | `omanix.lock` (in-shell PAM + fingerprint) |
| Idle | Hypridle (`desktop/hypridle.nix`) | `omanix.idle` (shell service) |
| Clipboard / emoji | cliphist + walker providers | `omanix.clipboard`, `omanix.emojis` |
| Background | swaybg + hyprpaper | `omanix.background` overlay |
| Theming | static build-time palette, per-app string interpolation, 2 themes, no runtime switch | palette → `colors.toml` + `shell.toml`; hybrid switching (D2) |
| Hyprland | ✅ Lua via `mkLuaInline` | (done) — rewire binds to shell IPC |
| CLI scripts | 32 `omanix-*` (`pkgs/omanix-scripts/`) | superset incl. `omanix-shell`, `omanix-bar`, `omanix-osd`, plugin CLI |
| Agents | claude-code + opencode via `llm-agents`, opt-in | launcher + picker + usage widget + crash-watch |

Key files: `flake.nix`, `lib/{themes,theme-schema,color-utils}.nix`,
`modules/home-manager/theme/default.nix`, `modules/home-manager/ui/{waybar,walker,elephant,
mako,swayosd}.nix`, `modules/home-manager/desktop/hyprland/{visuals,bindings,autostart}.nix`,
`modules/home-manager/desktop/{hyprlock,hypridle}.nix`, `pkgs/omanix-scripts/`.

---

## 4. Phased plan

Phases 1 → 3 are a hard chain (nothing works until Quickshell boots *and* is themed). Phase
4 is fully parallel — pick items off in any order; this is where "we can't support
everything" lives. Phase 5 is optional and depends on Phase 1.

### Phase 0 — Foundations 🟡

- [x] ✅ Branch `quattro` created.
- [x] ✅ Vendor a committed in-repo snapshot of omarchy's `shell/` under `vendor/omanix-shell/`; record the exact upstream rev in `vendor/PROVENANCE.md` (Q0-01). No source flake input.
- [x] ✅ Decide the `OMANIX_PATH` mechanism (Q0-02): **decided — see D5.** Single env var → the shell *code* package (`OMANIX_PATH = ${pkgs.omanix-shell}`, tree at `$out/shell/`); exported via the Hyprland `env` directive + dbus activation-env allowlist (omanix disables uwsm), **not** a synthetic checkout root. Out-of-tree refs decompose to PATH (`bin/`) and Nix-generated files (`config/`/`default/`).
- [x] ✅ Define the D1 rename ruleset as the re-runnable rename step of `scripts/vendor-omarchy.sh` (applied once at vendor time, output committed); verify its diff (Q0-03). **Done:** `apply_rename()` performs the case-preserving `omarchy`↔`omanix` swap (URLs excluded) plus the D5 structural rewrites — strips `omarchyPath + "/bin/"` prefixes (→ bare `omanix-*` PATH names) and repoints `config/omarchy/shell.json` + `default/omarchy/*` (`omanix-menu.jsonc`, `launcher.hides`) to in-store `$OMANIX_PATH/shell/{config,defaults}/…`. Deterministic + idempotent; audited via `git diff vendor/`.
- [x] ✅ Pin the shell's external-command contract and per-command disposition (Q0-05): KEEP / ephemeral-overlay / out-of-scope-disable; derive the seeded `disabledPlugins` set and note the two non-rename landmines. **Done:** disposition table verified against the committed renamed tree (added the missing `omanix-font-*` picker → CUT; recategorized `remove-launcher-entry` → KEEP); open features resolved (weather + reminders KEEP, disk-speedtest + dictation DISABLE); seeded scope pinned — `disabledPlugins = [omanix.dropbox, omanix.nightlight, omanix.disk-speedtest]` plus bar-layout + menu-jsonc omissions (Q1-03). Both landmines confirmed & assigned: `pacman` guard prelude `MenuModel.js:~399-420`/`Menu.qml:432` → Q1-08; `pkexec tailscale` `tailscale/Service.qml:353` → Q4-07. **Reconcile with D5:** Q0-03 strips **all** `$OMANIX_PATH/bin/` prefixes generically (a superset of this contract), so it agrees by construction; every KEEP'd command must ship on PATH via `pkgs.omanix-scripts`.
- [ ] Confirm scope cuts with a one-liner in each retired area.

### Phase 1 — Quickshell bring-up (KEYSTONE) 🟡

- [x] ✅ Package Quickshell (Q1-01). **Done:** the pinned nixpkgs `pkgs.quickshell` (0.3.0, `nixos-unstable`) already ships **all 13** required modules — `Quickshell.{Io,Wayland,Hyprland,Bluetooth,Networking}` + `Quickshell.Services.{Mpris,Notifications,Pam,Pipewire,Polkit,SystemTray,UPower}` — and is substitutable from `cache.nixos.org` (no compile). No override or upstream flake input needed: upstream CMake defaults every feature ON and nixpkgs disables none; the network/bluetooth/service modules are DBus-only at build time (their daemons are a *runtime* concern for Q1-03/Phase 4). Verified by store-path module listing + two headless smoke tests (scratch all-imports QML and the real `vendor/omanix-shell` tree — both load with zero module-resolution errors). Exposed via a documented pass-through `quickshell = prev.quickshell;` in `flake.nix` `overlays.default` (the single override point). **R1 retired.** Details in `tasks/Q1-01-quickshell-package-validate.md`.
- [x] ✅ New pkg `pkgs/omanix-shell/` — install the committed, already-renamed `vendor/omanix-shell/` QML tree (~175 files) into the store (no fetch, no build-time rename), ship plugin assets (emojis.json, agent SVGs, per-plugin helper scripts) alongside. **Done (Q1-02):** `stdenv.mkDerivation` with `dontBuild` + plain `cp -r` (no text mutation) installs the tree at `$out/share/omanix/shell/`, so `OMANIX_PATH = ${pkgs.omanix-shell}/share/omanix` and launch is `quickshell -n -p $OMANIX_PATH/shell` (task-spec layout, consistent across Q0-02/Q1-02/Q1-03 — supersedes D5's earlier `$out/shell` wording). Nothing synthetic glued alongside. Exposed via `overlays.default` + a `packages.x86_64-linux.omanix-shell` output. Verified: 175/175 files, all assets, no `OMARCHY_PATH`, `nix flake check` passes.
- [x] ✅ New HM module `modules/home-manager/desktop/quickshell.nix`: export `OMANIX_PATH`, autostart `quickshell -n -p $OMANIX_PATH/shell` from Hyprland, seed a default `shell.json` to `~/.config/omanix/shell.json` (activation **copy**, not symlink — it's user-mutable + IPC-written). **Done (Q1-03):** options under `omanix.quickshell.*` (namespaced away from the pre-existing zsh `omanix.shell.*`); declared base is minimal (`version` + Q0-05 `disabledPlugins`), deep-merged over the user file each activation (declared wins, runtime-only keys preserved). **Per D5:** `OMANIX_PATH` exported via the gated `env` entry in `desktop/hyprland/envs.nix` **plus** appended to the `dbus-update-activation-environment` allowlist in `desktop/hyprland/autostart.nix` — explicitly **not** uwsm. Old stack coexists (no removal — Q3-02).
- [ ] Get built-in plugins loading: bar, notifications, osd, menu, clipboard, background, lock, idle, polkit, media, network, bluetooth, tray, power.
  - [x] ✅ **bar** (Q1-05): `omanix.quickshell.bar.*` options generate the full `bar` block into Q1-03's `declaredBase` — position/transparent/centerAnchor + a `layout` reproducing the Waybar content set (`omanix.workspaces`, `omanix.active-window`, `omanix.clock`, `omanix.indicators` [ScreenRecording, Dnd, StayAwake], `omanix.tray`, `omanix.bluetooth`, `omanix.network`, `omanix.audio`, `omanix.power`). SystemUpdate/NightLight/Dictation omitted per Q0-05; media (Q1-13) and menu (Q1-08) deferred. Options nest under `omanix.quickshell.*` per **D6**. Runtime render pending a live session.
  - [x] ✅ **notifications** (Q1-06): the vendored `omanix.notifications` plugin needed **no QML changes** — loads by default, IPC target `notifications` (`toggleDnd`/`dismissOne`/`dismissAll`/`invokeLast`/`showHistory`), DND in `~/.local/state/omanix/notifications.json`, history+avatars under `notifications/{history,images}/`, safe-argv click actions. **Retired mako entirely** (module + import + autostart) — omarchy 4.0.2 dropped it — pulling the mako slices of Q3-01/02/03 forward. Rewired the 5 notification keybinds to `omanix-shell notifications …`, added `Dnd` to the bar indicators, and shipped `omanix-hyprland-focus-app` (click-without-action fallback). No new `shell.json`/option surface (DND is runtime state per D2). Popup/suppression/history are runtime-only to verify.
  - [x] ✅ **osd** (Q1-07): the vendored `omanix.osd` plugin needed **no QML changes** — `keepLoaded: true`, IPC target `osd` (`show <payloadJson>`/`close`/`state`/`ping`). Ported `bin/omarchy-osd` → `omanix-osd` (`pkgs/omanix-scripts`, `selfPath` to reach sibling `omanix-shell`): builds the `{icon,message,value,progressText,max,duration}` payload with `jq` and forwards `omanix-shell -q osd show` best-effort (down shell no-ops, exit 0). Upstream's `omarchy osd --help` dispatcher call replaced with an inline usage block. No new option surface. Media-key rebind (Q3-01) and volume/brightness producers (Q4-03) stay out of scope; overlay render is runtime-only to verify.
- [ ] Port the `omanix-shell` IPC CLI (`quickshell ipc` wrapper) + `omanix-bar`, `omanix-osd`, `omanix-restart-shell`, `omanix-refresh-shell`, `omanix-shell-config`.

### Phase 2 — Theming → shell (hybrid, D2) ⬜

- [ ] Extend `lib/themes.nix` / theme resolution to emit, per theme, a `colors.toml` and a `shell.toml` into the store, in the format the QML shell consumes. Reuse the existing palette (color0-15 + semantic already present).
- [ ] Port `default/themed/shell.toml.tpl` semantics into Nix (13 sections: bar, hyprland, controls, spacing, font, popups, tooltip, notifications, launcher, menu, polkit, lock, image-picker). Generate from palette rather than templating text where practical.
- [ ] Build **all** themes' tomls (declarative baseline); apply the declared `omanix.theme` on activation via IPC `applyTheme` (source of truth).
- [ ] Port `omanix-theme-set` for runtime (ephemeral) switching + `omanix-theme-switcher` (image picker) + background helpers (`omanix-theme-bg-{cache,switcher,current}`).
- [ ] Port the theme security boundary (git-cloned themes may ship color data only; `.lua`/terminal/vscode denied).
- [ ] Reconcile stale docs (README/CLAUDE claim "only Tokyo Night"; `catppuccin-mocha` also ships).

### Phase 3 — Retire the old stack ⬜

- [ ] Once shell equivalents work, remove/disable `ui/{waybar,walker,elephant,mako,swayosd}.nix` and `desktop/{hyprlock,hypridle}.nix` (gate behind an option during transition if useful).
- [ ] Rewire `desktop/hyprland/bindings.nix`: replace `omanix-*`/walker calls with `omanix-shell` IPC (SUPER+SPACE → menu toggle, clipboard, emoji, panel toggles, lock).
- [ ] Rewire `desktop/hyprland/autostart.nix`: drop mako/swayosd-server/hyprpolkitagent/swaybg autostarts now hosted in the shell.
- [ ] Port clipboard/menu helper CLIs: `omanix-clipboard-{open,paste-file,paste-text}`, `omanix-menu-{clipboard,emoji,emoji-insert,images,timezone,plugin}`.
- [ ] Retire `omanix-menu.sh` bash surface in favor of the shell menu (or keep as fallback).
- [ ] Fix dangling references found in recon: `omanix-battery-remaining`, `omanix-restart-walker` (walker being removed).

### Phase 4 — Plugin system + independent helpers (parallel) ⬜

Plugin system:
- [ ] Port `omanix-plugin-{add,clone,enable,disable,update,remove,list,validate,catalog}` + `omanix-menu-plugin`. Pure bash + jq + git + gum. User plugins → `~/.config/omanix/plugins/` (writable, outside store). Built-ins immutable in the store is fine.

Independent CLI helpers (each self-contained; port as desired):
- [ ] **Hardware detection**: `omanix-hw-{laptop,laptop-closed,clamshell,display,fingerprint,nvidia,intel-sof,webcam}`. Some map to NixOS `hardware.*` options instead of runtime probes — decide per item.
- [ ] **Audio tuning**: `omanix-audio-tuning` (PipeWire filter-chain EQ/limiter service; data-driven `default/audio/tunings/`; ships dell-xps-2026, needs `lsp-plugins-lv2`), sink resolution helpers, `omanix-restart-audio`.
- [ ] **Network**: `omanix-network-{band,qr,password,speedtest,status}`; enterprise 802.1X.
- [ ] **Capture**: `omanix-capture-{qr,region,text(OCR),webcam-list,webcam-resize,screenrecording-with-webcam}` + `omanix-transcode` (image → compressed JPEG to clipboard).
- [ ] **Security**: `omanix-setup-security-sshd` → reframe as NixOS `services.openssh` + firewall options; `omanix-setup-security-sudoless-docker` → `users.groups`/module option. Port the *intent*, not the imperative scripts.
- [ ] **Tailscale taildrop**: `omanix-tailscale-{send,receive}` + receiver systemd user service.
- [ ] **Gaming**: `omanix-install-gaming-battlenet` (umu-launcher + GE-Proton), `omanix-games-retro-{install,cores}` (RetroArch). Reframe installs as packages/options.
- [ ] **Plymouth**: `omanix-plymouth-{set,list,current,switcher}` — boot splash theming. Nix builds the theme declaratively; runtime switcher is ephemeral (mirror D2).
- [ ] **Palette-only theme targets** (no shell dependency): `omanix-theme-set-{tmux,claude,pi,browser-policy}`, `omanix-theme-osc`. Straightforward.
- [ ] **herdr**: package `herdr`; ship `config/herdr/config.toml`; bindings (`Super+Ctrl+Return`); shell fns (`hdl/hds/hdlm/hsl`); `omanix-menu-herdr-keybindings`.
- [ ] **Custom branding**: `omanix-branding-{about,screensaver}` + `omanix-transcode-ascii` + About screen; swappable logo (declarative default + runtime override); wires the existing `pkgs/omanix-screensaver/`.

### Phase 5 — AI agents (optional; depends on Phase 1) ⬜

- [ ] `omanix-agent` launcher + `omanix-default-agent` picker (menu Setup › Defaults › Agent), scoped to agents available via `llm-agents`.
- [ ] `omanix.agents` usage widget (Quickshell bar plugin; Python collectors for claude/codex/fireworks — stdlib only, portable). Discovers agents from JSON records.
- [ ] `omanix-crash-watch` systemd user service + `omanix-agent-crash` (coredump → diagnose). Needs `systemd-coredump`.
- [ ] Provision agent skills as symlinks into `~/.claude`, `~/.codex`, etc.

---

## 5. Risks & open questions

- **R1 (highest):** Quickshell packaging with all Qt service submodules on NixOS. Validate in Phase 1 before committing to the rest.
- **R2:** The D1 rename sweep must not corrupt QML string literals / URLs / user-facing text. Scope substitutions to code contexts; review the patch diff on every upstream bump.
- **R3:** `shell.json` and `~/.config/omanix/plugins/` are user-mutable and IPC-written — must be seeded (copy on activation), never symlinked into the store.
- **R4:** Hyprland version. Omanix pins `hyprland` v0.55.2; the vendored shell may assume a newer Hyprland/IPC. Check and bump if needed.
- **Q1:** Where does per-user runtime state live? Omarchy uses `~/.local/state/omarchy/`; adopt `~/.local/state/omanix/` for toggles/current/markers the shell needs.
- **Q2:** Keep `omanix-menu.sh` (bash/dmenu) as a fallback surface, or fully retire it once the shell menu lands?

---

## 6. Reference

The full 4.0.2 feature inventory (all subsystems, with per-area NixOS porting notes) was
produced during planning and lives in the omarchy repo analysis. Key omarchy source paths
to consult while porting:

- Shell: `shell/` tree, `docs/omarchy-shell.md`, `agents/skills/shell-dev.md`, `shell/plugins/README.md`, `config/omarchy/shell.json`
- Theming: `bin/omarchy-theme-color`, `bin/omarchy-theme-set-templates`, `default/themed/*.tpl`, `docs/theming.md`
- Plugins: `bin/omarchy-plugin-*`, `shell/services/PluginRegistry.qml`
- Agents: `bin/omarchy-agent*`, `bin/omarchy-default-agent`, `shell/plugins/agents/`
- Package set (source of truth for what to install): `install/omarchy-base.packages`, `install/omarchy-other.packages`, and the retired-package list in `bin/omarchy-upgrade-to-quattro`
