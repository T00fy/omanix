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

### D1 — Naming: rename everything to `omanix-*`

The vendored Quickshell `shell/` tree hardcodes `omarchy-*` command names, `omarchy.*`
plugin IPC ids, and reads `$OMARCHY_PATH`. We rename all of it to the omanix namespace
(`omanix-*`, `omanix.*`, `$OMANIX_PATH`).

**Mitigation for upstream re-syncs:** do the rename as a **deterministic patch phase in the
nix derivation** that vendors the shell, not as a hand-edited fork. A `substituteInPlace` /
`sed` sweep over `omarchy` → `omanix`, `OMARCHY_PATH` → `OMANIX_PATH`, `omarchy.` → `omanix.`
(plugin ids), applied at build time to a pinned upstream source. Re-syncing a newer omarchy
then becomes: bump the source rev + rebuild. Keep the sweep patterns in one place and
review its diff on each bump. Watch for false positives (URLs, user-facing strings, the
literal word in docs) — pin the substitution to code contexts where possible.

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

### Phase 0 — Foundations ⬜

- [ ] ✅ Branch `quattro` created.
- [ ] Pin an upstream omarchy source rev to vendor `shell/` from (record the rev here: `__________`).
- [ ] Decide the `OMANIX_PATH` mechanism: what store path the shell resolves, how it's exported into the Hyprland/uwsm session env (omarchy relies on uwsm setting `OMARCHY_PATH`).
- [ ] Stand up the rename patch phase (D1) as a reusable function/derivation step; verify its diff on the pinned source.
- [ ] Pin the shell's external-command contract and per-command disposition (Q0-05): KEEP / ephemeral-overlay / out-of-scope-disable; derive the seeded `disabledPlugins` set and note the two non-rename landmines.
- [ ] Confirm scope cuts with a one-liner in each retired area.

### Phase 1 — Quickshell bring-up (KEYSTONE) ⬜

- [ ] Package Quickshell. **Verify** `pkgs.quickshell` (nixpkgs) / the upstream Quickshell flake builds with the required Qt service modules: `Quickshell.{Io,Wayland,Hyprland,Bluetooth,Networking}` and `Quickshell.Services.{Mpris,Notifications,Pam,Pipewire,Polkit,SystemTray,UPower}`. This is the single biggest technical risk — validate early.
- [ ] New pkg `pkgs/omanix-shell/` — vendor omarchy's `shell/` QML tree (~175 files) into the store, apply the D1 rename patch, ship plugin assets (emojis.json, agent SVGs, per-plugin helper scripts) alongside.
- [ ] New HM module `modules/home-manager/desktop/shell.nix` (or `ui/quickshell.nix`): export `OMANIX_PATH`, autostart `quickshell -n -p $OMANIX_PATH/shell` from Hyprland, seed a default `shell.json` to `~/.config/omanix/shell.json` (activation **copy**, not symlink — it's user-mutable + IPC-written).
- [ ] Get built-in plugins loading: bar, notifications, osd, menu, clipboard, background, lock, idle, polkit, media, network, bluetooth, tray, power.
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
- [ ] **Capture**: `omanix-capture-{qr,region,text(OCR),webcam-list,webcam-resize,screenrecording-with-webcam}`.
- [ ] **Security**: `omanix-setup-security-sshd` → reframe as NixOS `services.openssh` + firewall options; `omanix-setup-security-sudoless-docker` → `users.groups`/module option. Port the *intent*, not the imperative scripts.
- [ ] **Tailscale taildrop**: `omanix-tailscale-{send,receive}` + receiver systemd user service.
- [ ] **Gaming**: `omanix-install-gaming-battlenet` (umu-launcher + GE-Proton), `omanix-games-retro-{install,cores}` (RetroArch). Reframe installs as packages/options.
- [ ] **Plymouth**: `omanix-plymouth-{set,list,current,switcher}` — boot splash theming. Nix builds the theme declaratively; runtime switcher is ephemeral (mirror D2).
- [ ] **Palette-only theme targets** (no shell dependency): `omanix-theme-set-{tmux,claude,pi,browser-policy}`, `omanix-theme-osc`. Straightforward.
- [ ] **herdr**: package `herdr`; ship `config/herdr/config.toml`; bindings (`Super+Ctrl+Return`); shell fns (`hdl/hds/hdlm/hsl`); `omanix-menu-herdr-keybindings`.

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
