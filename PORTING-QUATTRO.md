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
**Q1-12 decided idle keeps `omanix.idle.*`** (not `omanix.quickshell.idle.*`): back-compat, and
the ticket explicitly said preserve the option names. Q1-12 maps `omanix.idle.screensaver.timeout`
/ `omanix.idle.lock.timeout` into the shell's `idle` block; the remaining `omanix.idle.*` stages
(dim/dpms/suspend) have no shell equivalent and stay on the (gated) hypridle daemon.

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
- [x] ✅ Get built-in plugins loading: bar, notifications, osd, menu, clipboard, background, lock, idle, polkit, media, network, bluetooth, tray, power.
  - [x] ✅ **bar** (Q1-05): `omanix.quickshell.bar.*` options generate the full `bar` block into Q1-03's `declaredBase` — position/transparent/centerAnchor + a `layout` reproducing the Waybar content set (`omanix.workspaces`, `omanix.active-window`, `omanix.clock`, `omanix.indicators` [ScreenRecording, Dnd, StayAwake], `omanix.tray`, `omanix.bluetooth`, `omanix.network`, `omanix.audio`, `omanix.power`). SystemUpdate/NightLight/Dictation omitted per Q0-05; media (Q1-13) and menu (Q1-08) deferred. Options nest under `omanix.quickshell.*` per **D6**. Runtime render pending a live session.
  - [x] ✅ **notifications** (Q1-06): the vendored `omanix.notifications` plugin needed **no QML changes** — loads by default, IPC target `notifications` (`toggleDnd`/`dismissOne`/`dismissAll`/`invokeLast`/`showHistory`), DND in `~/.local/state/omanix/notifications.json`, history+avatars under `notifications/{history,images}/`, safe-argv click actions. **Retired mako entirely** (module + import + autostart) — omarchy 4.0.2 dropped it — pulling the mako slices of Q3-01/02/03 forward. Rewired the 5 notification keybinds to `omanix-shell notifications …`, added `Dnd` to the bar indicators, and shipped `omanix-hyprland-focus-app` (click-without-action fallback). No new `shell.json`/option surface (DND is runtime state per D2). Popup/suppression/history are runtime-only to verify.
  - [x] ✅ **osd** (Q1-07): the vendored `omanix.osd` plugin needed **no QML changes** — `keepLoaded: true`, IPC target `osd` (`show <payloadJson>`/`close`/`state`/`ping`). Ported `bin/omarchy-osd` → `omanix-osd` (`pkgs/omanix-scripts`, `selfPath` to reach sibling `omanix-shell`): builds the `{icon,message,value,progressText,max,duration}` payload with `jq` and forwards `omanix-shell -q osd show` best-effort (down shell no-ops, exit 0). Upstream's `omarchy osd --help` dispatcher call replaced with an inline usage block. No new option surface. Media-key rebind (Q3-01) and volume/brightness producers (Q4-03) stay out of scope; overlay render is runtime-only to verify.
  - [x] ✅ **menu** (Q1-08): the vendored `omanix.menu` plugin (launcher + hierarchical menu + app search) loads via `keepLoaded: true`; IPC route is the `shell` target's `summon`/`toggle omanix.menu '{"menu":"<id>"}'`. Authored the omanix-owned default tree `pkgs/omanix-shell/defaults/omanix-menu.jsonc` (Apps/Learn/Trigger/Style/Setup/System, adapted from the old `omanix-menu.sh`; every `action:` maps to a command already on PATH; no `when`/`checked` guards in v1) and installed it to `$OMANIX_PATH/shell/defaults/` via the shell package (D5: Nix-shipped, not vendored). Replaced the walker-driven `omanix-menu` script with a thin `omanix-shell` IPC shim (`selfPath`, `[toggle|show|hide] [<menu-id>]`) — this satisfies **Q3-05**'s "retire `omanix-menu.sh`". Added `{ id = "omanix.menu"; }` to the bar `layout.left` default (closes the Q1-05 deferral). **Two vendored QML edits** (recorded per Q0-01, both landmines the D1 rename couldn't fix): `AppLibrary.qml` launch drops `uwsm-app -- ` (omanix runs Hyprland without uwsm → `gtk-launch` direct, `pkgs.gtk3` added to the shell's `home.packages`); `MenuModel.js guardHelpers()` strips the `pacman -Qq/-Qi/-Q` machinery (kept the portable `omanix-cmd-present/missing`; `omanix-pkg-*` dropped — a user-extension pkg guard now resolves undefined → row hidden, not mis-answered). Walker/elephant removal + SUPER+SPACE rebinding stay out of scope (Q3-03/Q3-01). Launcher/search/dispatch are runtime-only to verify.
  - [x] ✅ **clipboard + emojis** (Q1-09): the vendored `omanix.clipboard` + `omanix.emojis` plugins needed **no QML changes** — both are first-party `keepLoaded` overlays that load unless listed in `disabledPlugins`; `emojis.json` + `capture.sh` are already vendored and resolve in-store, so `pkgs/omanix-shell/` is untouched. Clipboard self-captures via `wl-paste --watch capture.sh` (no cliphist) into a bare newest-first JSON array at `~/.local/state/omanix/clipboard-history.json`. Shipped five CLIs in `pkgs/omanix-scripts`, reconstructed from the verified QML call contract (upstream `bin/` was never vendored): `omanix-menu-emoji` + `omanix-clipboard-open` are thin `omanix-shell` IPC shims (`selfPath`), `omanix-menu-emoji-insert` + `omanix-clipboard-paste-{text,file}` shell out to `wl-clipboard`/`wtype` (added the `wtype` input). `--history-index N` reads `.[N]`; paste reads the untruncated `.text` back (the >1MB/UTF-16 hardening lives in `capture.sh` + `ClipboardHistory.js`, not the CLIs). Added `capture.sh`'s runtime deps (`wl-clipboard`, `util-linux`, `procps`, `perl`) to the shell module's `home.packages`. SUPER+CTRL+V/E rebinding (Q3-01), walker/elephant + cliphist-autostart removal (Q3-02/Q3-03), and the broader `omanix-menu-*` set (Q3-04) stay out of scope. Picker/paste/insert are runtime-only to verify.
  - [x] ✅ **background** (Q1-10): the vendored `omanix.background` plugin needed **no QML changes** — it is a first-party `service` (id `omanix.background`, IPC target `background`, layershell namespace `omanix-background`) that auto-loads since it is absent from `disabledPlugins`. `Background.qml` resolves its image at startup via `readlink -f ~/.local/state/omanix/current/background`, so the only glue is a new `home.activation.omanixBackgroundState` in `desktop/quickshell.nix` that seeds that link (writable, `ln -sfn`) to the declared `config.omanix.activeTheme.assets.wallpaper` store path. No new option, no `shell.json` block. D2-aligned: rebuild reasserts the declared theme; a runtime switcher (Q2-05) may repoint the link ephemerally. swaybg autostart + `hyprpaper.nix` left in place — removal is Q3-02. Full-screen render/persistence are runtime-only to verify.
  - [x] ✅ **lock** (Q1-11): the vendored `omanix.lock` plugin needed **no QML changes** — it is a first-party `keepLoaded` service (id `omanix.lock`, IPC target `lock` with `lock`/`isLocked`/`status`/`preview`; locks via `WlSessionLock`) that auto-loads since it is absent from `disabledPlugins`. The plugin refuses to lock unless `/etc/pam.d/omanix-lock-password` exists and authenticates against that PAM service (fingerprint is a separate `omanix-lock-fingerprint` service, probed via `fprintd-list`). The Nix-specific work is declarative PAM: new NixOS module `modules/nixos/security.nix` declares `security.pam.services.omanix-lock-password` (unix auth, `fprintAuth = false` so the password context stays password-only) and, gated on `services.fprintd.enable`, `security.pam.services.omanix-lock-fingerprint` (`unixAuth = false`, `fprintAuth = true`) — no script writes `/etc/pam.d`. Options under `omanix.security.lock.*` (`enable`, `fingerprint.enable`). On-demand lock is the generic wrapper `omanix-shell lock lock`; the lock timeout source is `shell.json` `idle.lock`, wired into the declared base by Q1-12 (not added here). Faillock omitted (plain password auth). Fingerprint *enrollment*/fprintd enablement is Q4-02; keybind/idle rewiring + Hyprlock removal are Q3-01/Q1-12/Q3-03. Follow-ups: the plugin best-effort-calls four not-yet-existing helpers (`omanix-hyprland-session-locked`, `omanix-system-wake`, `omanix-brightness-{keyboard,display}`) — non-blocking, core lock/unlock works without them; and the old `omanix-lock-screen`'s bitwarden-lock/xkb-reset is not carried over (revisit with Q3-01). Lock/unlock/fingerprint are runtime-only to verify.
  - [x] ✅ **idle** (Q1-12): the vendored `omanix.idle` service (`keepLoaded`, IPC target `idle`) honors **only** `idle.screensaver` + `idle.lock` (seconds) and shells out to external glue. Mapping (`desktop/quickshell.nix`): added an `idle` block to Q1-03's `declaredBase` — `omanix.idle.screensaver.timeout` → `idle.screensaver`, `omanix.idle.lock.timeout` → `idle.lock`; reconciled by the existing deep-merge (declared wins, no activation change). **D6:** kept the legacy `omanix.idle.*` namespace (not `omanix.quickshell.idle.*`). A disabled stage (`enable = false`) uses an `86400` "never" sentinel because the shell falls back to its built-in 150/300 on a missing key (omission can't disable). **Reconciliation:** `dim`/`dpms`/`suspend` have no shell equivalent and **stay on hypridle** — `desktop/hypridle.nix` is gated on `omanix.quickshell.enable` to drop its screensaver + lock listeners (shell owns them) and point `lock_cmd` at `omanix-system-lock`, keeping only dim/dpms/suspend; full hypridle retirement is Q3-03. **Vendored QML edit** (recorded in `vendor/PROVENANCE.md`): omanix's screensaver is a GTK **layer-shell** overlay (namespace `omanix-screensaver`), invisible to the upstream `openwindow`/class tracking, so `Service.qml` now also tracks it via Hyprland `openlayer`/`closelayer` (`screensaverLayerCount`/`screensaverPresentCount`). Shipped three glue CLIs in `pkgs/omanix-scripts`: `omanix-launch-screensaver` (GTK screensaver + declared logo), `omanix-system-lock` (`omanix-shell lock lock` + screensaver pkill), `omanix-system-wake` (`hyprctl dispatch dpms on`) — the latter two also resolve Q1-11 dangling refs. Screensaver *content* not rebuilt; media-key/idle keybind rewiring + hyprlock/hypridle removal remain Q3-01/Q3-03. Screensaver→lock sequencing/dismissal + DPMS/suspend are runtime-only to verify.
  - [x] ✅ **polkit / media / network / bluetooth / tray / power** (Q1-13): all six are first-party and needed **no QML changes** — they auto-load (absent from `disabledPlugins`) against the Quickshell service modules Q1-01 confirmed present (`Polkit`, `Mpris`, `Networking`, `Bluetooth`, `SystemTray`, `UPower`). Five of the six bar-widget ids (`omanix.network`, `omanix.bluetooth`, `omanix.tray`, `omanix.power`, `omanix.audio`) were already placed by Q1-05, so the Nix work was small: added `{ id = "omanix.media"; }` to the `bar.layout.center` default (before `omanix.clock`, matching omarchy) — its Mpris+Pipewire service auto-loads to feed it. **polkit conflict:** `omanix.polkit` auto-loads and registers the DBus agent, so the old `hyprpolkitagent` autostart (`desktop/hyprland/autostart.nix`) is now gated on `!omanix.quickshell.enable` (sole-agent when the shell is up; pulls part of Q3-02 forward, à la Q1-06/mako). **NetworkManager (decision — leave to host):** the network panel drives `nmcli`/`Quickshell.Networking`; omanix does **not** enable NetworkManager in any module — documented on the layout entry, hosts must set `networking.networkmanager.enable`. `wl-copy`/`uuidgen` already in `home.packages`; bluetooth already enabled. **Follow-ups (non-blocking — plugins load without them):** the `omanix-*` helpers the panels call on user action are unimplemented — `omanix-hw-laptop-closed`/`omanix-battery-status`/`omanix-system-stats` (Q4-02), `omanix-audio-output-set-default` (Q4-03), `omanix-network-*`/`omanix-dns`/`omanix-bluetooth-*`/`omanix-powerprofiles-*` (Q4-04). Panel keybinds Q3-01; Waybar/applet removal Q3-02/Q3-03. Load + panel/dialog interaction are runtime-only to verify.
- [ ] Port the `omanix-shell` IPC CLI (`quickshell ipc` wrapper) + `omanix-bar`, `omanix-osd`, `omanix-restart-shell`, `omanix-refresh-shell`, `omanix-shell-config`.

### Phase 2 — Theming → shell (hybrid, D2) 🟡

- [x] ✅ **colors.toml renderer** (Q2-01): new pure `lib/theme-toml.nix` (`{ colors, mode }: -> string`) renders an omarchy-format `colors.toml` from the existing palette; exposed as `omanixLib.renderColorsToml` + `omanixLib.themesColorsToml` (all themes, keyed by slug — Q2-03 writes these to the store). Mixing helpers (`rgbToHex`/`mix`/`darken`/`lighten`, integer-only) added to `lib/color-utils.nix`. `meta.mode` added to `lib/theme-schema.nix` (enum dark/light, default "dark") + both themes. Mapping is 1:1 where possible (`bright_foreground ← cursor`, `muted ← color8`, `orange = mix(red,yellow,50)` all exact for tokyo-night); surface shades + `brown` derived by mixing. All 30 reference keys present for both themes; `nix flake check` passes.
- [x] ✅ **shell.toml renderer** (Q2-02): new pure `lib/shell-toml.nix` (`{ colors, hyprlandActiveBorder ? null }: -> string`) renders all **13 sections** (bar, hyprland, controls, spacing, font, popups, tooltip, notifications, launcher, menu, polkit, lock, image-picker) from the existing palette; exposed as `omanixLib.renderShellToml` + `omanixLib.themesShellToml` (all themes, keyed by slug — Q2-03 writes these to the store). Only 4 palette-derived colors are needed (`background`/`foreground`/`accent`/`red←color1`) plus one `mix` (`[lock] placeholder`, reuses `color-utils.mix`) and the two `[hyprland]` border tokens; `shell_gradient` ported as `color-utils.shellGradient` (solid fallback since neither shipped theme defines `hyprland_active_border`, matching omanix's solid `rgb(accent)` border). Output is lean (constants verbatim, comments in the generator source, cross-section refs literal). Both themes lint clean via `taplo`; every upstream non-comment key present; `nix flake check` passes.
- [x] ✅ **build all themes + apply on activation** (Q2-03): `modules/home-manager/desktop/quickshell.nix` (the only file changed — added `omanixLib` to its args) bakes every theme's `<slug>/{colors.toml,shell.toml}` into the store via `pkgs.linkFarm` from Q2-01/Q2-02's slug-keyed `omanixLib.themesColorsToml`/`themesShellToml`, exposed as internal readOnly `omanix.quickshell.themesDir` (mirrors `declaredBaseFile`; Q2-04's `omanix-theme-set` resolves switches against it). New `home.activation.omanixThemeState` (mirrors `omanixBackgroundState`) seeds `~/.local/state/omanix/current/theme` as a **writable symlink into the store** (`ln -sfn "${themesStore}/${config.omanix.theme}"`), then best-effort base64-encodes the seeded tomls and calls `omanix-shell -q shell applyTheme` (guarded, never fails activation). **Cold start vs live:** the shell reads `current/theme/*` on launch (`Color.qml` unwatched FileViews) so a down shell no-ops and picks up the declared theme on next start; the IPC push (`shell.qml:879` `applyTheme` takes base64 file *contents*, not a path) re-themes a running one. **Symlink-not-copy** resolves the ticket hedge — the shell only reads `current/theme` (`applyTheme` never touches disk), so a symlink is safe + Nix-idiomatic + matches the Q1-10 precedent. **D2 revert:** activation always re-seeds `current/theme → <declared slug>` and re-applies; nothing runtime-written is read by activation, so a prior `omanix-theme-set` is overwritten. Unknown-theme eval failure already comes from `omanix.theme = types.enum availableThemes`. `nix flake check` passes; the store derivation builds for both themes. Live apply/revert are runtime-only to verify.
- [x] ✅ **theme-color resolver + theme-set** (Q2-04): two new scripts in `pkgs/omanix-scripts`. `omanix-theme-color` is the shared `colors.toml` palette resolver — ported near-verbatim from upstream (`--file`/`--all`/`--raw`/`<key> [fallback]`, the `mix_color` awk helper, the legacy short-name + ANSI `colorN` alias cascade, shade derivation, and the `mode` → `theme_type` → `light.mode` → luminance → dark precedence), only the D1 rename + default path (`~/.local/state/omanix/current/theme/colors.toml`) changed; deps `[bash coreutils gawk]`. `omanix-theme-set <slug>` is a lean **ephemeral** switch: normalizes name→slug, validates against the built theme set via injected `OMANIX_THEMES_DIR` (= `omanix.quickshell.themesDir`, wired through the `omanix-scripts.override` mirroring `shellDefaults`), `flock`-serializes, repoints `current/theme` (`ln -sfn`, same form as `omanixThemeState` activation), then base64s + pushes `omanix-shell -q shell applyTheme`. **Palette only** — background is a separate axis (Q2-05); all of upstream's git-theme staging / `INSTALLED_THEME_DENIED` / template-regen machinery is dropped (themes are read-only + trusted in-store; boundary revisited in Q2-06 only if user themes land). Best-effort guarded loop calls `omanix-theme-set-{tmux,claude,pi,browser}` if present (Q4-10). `nix flake check` passes; the scripts package builds with both binaries on PATH. Live apply/revert are runtime-only to verify.
- [x] ✅ **background helpers** (Q2-05): shipped the wallpaper axis. New shared image-picker CLI `omanix-menu-images` (near-verbatim port of `omarchy-menu-images` — vips thumbnail cache under `$XDG_CACHE_HOME/omanix/image-selector`, base64 row transit, drives the shell's `image-selector` IPC; **also lands the Q3-04 `omanix-menu-images` item**) plus `omanix-theme-bg-{set,switcher,current,cache}`. `omanix-theme-bg-set` repoints `~/.local/state/omanix/current/background` (`ln -nsf`) + pushes `omanix-shell -q background set` (satisfies the `Background.qml:113` double-click contract); `-bg-switcher` opens the picker over the active theme's wallpapers; `-bg-current`/`-bg-cache` are the prettify/pre-warm leaves. **Reconciliation:** rewrote the legacy `omanix-theme-bg-next` off swaybg/`OMANIX_WALLPAPERS`/`$XDG_RUNTIME_DIR` onto the `current/background` symlink model (delegates to `-bg-set`) — one source of truth; dropped the dead `wallpaperList` wiring. **Nix glue:** extended the Q2-03 `themesStore` linkFarm so each `<slug>/backgrounds/` symlinks that theme's declared `assets.wallpapers`, so the picker resolves `current/theme/backgrounds` for whichever theme `current/theme` points at — no new state link or env var. **D2:** runtime picks are ephemeral overlays on `current/background`; `omanixBackgroundState` re-seeds the declared `activeTheme.assets.wallpaper` each rebuild. **Deferred:** `omanix-theme-switcher` (theme picker) — the `Background.qml` right-click no-ops gracefully when absent; no previews store built. **Declared-only:** no `~/.config/omanix/backgrounds/<slug>` user dir; picker/cycler scan the theme's declared wallpapers only. `nix flake check` passes; the scripts package builds (all six binaries on PATH, vips wired) and both themes bake their `backgrounds/`. Live picker/switch/revert are runtime-only to verify.
- [x] ✅ **theme security boundary** (Q2-06): document-only. omanix has no untrusted-theme ingestion path — `omanix-theme-set` accepts a slug, applies a traversal guard (reject empty / leading-`.` / contains-`/`), and resolves against the trusted store `$OMANIX_THEMES_DIR/<slug>` before repointing the `current/theme` symlink; nothing arbitrary is accepted/copied/staged, so the store *is* the allowlist and the boundary holds by construction (upstream's `~/.config` git-clone staging flow doesn't exist here). The script's security comment now states this and records the denied-file set (`.lua`, `alacritty.toml`/`foot.ini`/`ghostty.conf`/`kitty.conf`, `vscode.json`; no symlink following) to port *if* an untrusted `--file`/cloned-user-theme source ever lands. No ingestion code or dormant guard shipped (per Q2-04's "revisit only if user themes land").
- [x] ✅ **reconcile stale theme docs** (Q2-07): fixed the theme-count contradiction — `README.md` and `CLAUDE.md` now enumerate both shipped themes (Tokyo Night + Catppuccin Mocha) and point at `lib/themes.nix` as the source of truth. Left the "no runtime theme switching" claims accurate for the shipped `main` product (the D2 hybrid switch lives on the unmerged quattro stack — the ticket's constraint is not to claim runtime switching before it merges) and left the waybar/walker/mako/swayosd stack references intact (still accurate pre-Phase-3; broader quattro doc rewrite out of scope).

### Phase 3 — Retire the old stack ⬜

- [x] ✅ **Remove old-stack modules; commit to Quickshell** (Q3-03): deleted the fully-replaced HM modules `ui/{waybar,walker,elephant}.nix` + `desktop/{hyprlock,hyprpaper}.nix` (and their imports, `assets/branding/walker-layout.xml`, `docs/{waybar,walker,hyprlock}.md`); dropped the `walker`/`elephant` **flake inputs** + regenerated `flake.lock`; de-walkered `scripts/default.nix` + `pkgs/omanix-scripts/default.nix` (removed the `omanix-launch-walker` derivation and the now-unused `walker`/`waybar`/`hyprlock`/`swaybg`/`bitwarden-cli`/`envsubst` params). **Made Quickshell the default** (`omanix.quickshell.enable` → `default = true`, kept as a master switch) and collapsed the `!qs` fallbacks: `autostart.nix` now always launches the shell (old daemon list gone), `rules.nix` lost the `walker`/`waybar` layer rules. **`SUPER+K` keybindings viewer rewired to the shell** via a new shared `omanix-menu-dmenu` helper (stdin→`omanix.menu` dmenu mode round-trip, replacing `omanix-launch-walker --dmenu`); `omanix-menu-style` rewritten to pick a theme via that helper → `omanix-theme-set` → `omanix-theme-bg-switcher` (dropped the swaybg/glow legacy picker). **Retired `omanix-lock-screen`** (launched deleted hyprlock) → menu `system.lock` repointed to `omanix-system-lock`; its bitwarden-lock/xkb-reset are not carried over. **swayosd.nix + hypridle.nix kept**: swayosd media/brightness binds await **Q4-03**; hypridle now owns only dim/dpms/suspend (screensaver+lock are the shell's), `lock_cmd = omanix-system-lock`, `quickshellOwnsIdle`/`hyprlockCmd` conditionals removed. Cleared the incidental waybar signals: `omanix-cmd-screenrecord` refreshes via `omanix-shell -q omanix.indicators refresh`, `omanix-toggle-idle`'s dead `refresh_waybar` no-op dropped. `nix flake check` passes; `omanix-scripts` + `omanix-shell` build. **Deferred:** `omanix-scale.sh` still swaps waybar config variants for HiDPI — porting that scale/Moonlight subsystem to the Quickshell bar is its own follow-up (its waybar calls no-op harmlessly under the shell). Runtime (fresh session: one shell, `SUPER+K`/theme/lock via shell) is runtime-only to verify.
- [x] ✅ **Rewire `desktop/hyprland/bindings.nix`** (Q3-01): repointed launcher (`SUPER+SPACE → omanix-menu`), apps (`SUPER+ALT+SPACE → omanix-menu apps`), emoji (`SUPER+CTRL+E`), clipboard (`SUPER+CTRL+V → omanix-clipboard-open`), share (`SUPER+CTRL+S → trigger.share`), bar toggle (`SUPER+SHIFT+SPACE → omanix-toggle-bar`), lock (`SUPER+CTRL+L → omanix-system-lock`), and system panels `SUPER+CTRL+{A,B,W}` → `omanix.{audio,bluetooth,network}` + new `{D,P}` → `omanix.{monitor,power}` (retiring the pavucontrol/bluetui/wlctl TUI binds). **Media carve-out:** volume/brightness/mute/playerctl/audio-switch keys stay on `swayosd-client` and move to **Q4-03** (no producer CLI yet; `omanix-osd` displays only) — Q3-03's swayosd removal waits on it. `SUPER+K` (walker keybindings viewer → Q3-03) and `SUPER+CTRL+ALT+B` (`omanix-battery-remaining` dangling → Q3-05) left as-is.
- [x] ✅ **Rewire `desktop/hyprland/autostart.nix`** (Q3-02): refactored the `hyprland.start` hook to build its `hl.exec_cmd` list from a single Nix list gated by `qs = omanix.quickshell.enable` (replacing the brittle inline `lib.optionalString` interleaving). Under quickshell only the dbus-env update, the single `quickshell` launch, and `omanix.hyprland.extraAutostart` run; `swayosd-server`, `hyprpolkitagent`, both `cliphist` watchers, and `swaybg` are emitted only under `!qs` so the old stack still works unchanged when the shell is off (mako was already gone via Q1-06). **cliphist dropped under quickshell** — Q1-09's clipboard plugin self-captures via its own `capture.sh`, not cliphist. `hyprpaper.nix` module-level gating deferred to **Q3-03**. `nix flake check` passes; rendered Lua verified for both toggle states. Runtime (one shell process; no mako/swayosd/swaybg/hyprpolkitagent) is runtime-only to verify.
- [x] ✅ Port clipboard/menu helper CLIs (Q3-04): reconciled — every live helper was already delivered, so no new scripts. `omanix-clipboard-{open,paste-text,paste-file}` + `omanix-menu-{emoji,emoji-insert}` shipped by Q1-09; `omanix-menu-images` by Q2-05. The two remaining names resolve out: `omanix-menu-clipboard` **skipped** (zero callers — the picker is served by `omanix-clipboard-open` → `omanix-shell shell toggle omanix.clipboard`); `omanix-menu-timezone` **cut** (Q0-05 ratified; `time.timeZone` is declarative, D4). Removed the now-dangling clock middle-click `bar.run("omanix-menu-timezone")` from vendored `plugins/panels/clock/BarWidget.qml` (logged in `vendor/PROVENANCE.md`); middle-click falls through to `togglePanel()`. `omanix-menu-plugin` stays in **Q4-01** (plugin CLI). `nix flake check` + `omanix-scripts`/`omanix-shell` builds pass.
- [x] ✅ **Retire `omanix-menu.sh` + fix dangling refs** (Q3-05): reconciled — most of the ticket was already resolved by later work. `omanix-menu.sh` is no longer the bash/Walker control panel but a thin `omanix-shell shell toggle|show|hide omanix.menu` IPC shim (rewritten by Q1-08); `omanix-menu-{keybindings,style}.sh` were rewired off Walker onto `omanix-menu-dmenu` (Q3-03) — all three **kept as repurposed**, no fallback bash surface. `omanix-restart-walker` died with `ui/walker.nix` (Q3-03; zero references remain). The sole live dangler `omanix-battery-remaining` (`bindings.nix:244` "Show Battery") was **dropped** — battery % is shown by the bar's `omanix.power` widget (Q1-13); the sibling `SUPER+CTRL+ALT+T` "Show Time" (self-contained `date`) stays. Full `omanix-*` sweep audited: remaining residue is all benign (state-file names, PAM service names, separately-packaged commands, guarded `omanix-installed-service-*` probes, the deferred `omanix-scale.sh` subsystem's internal subcommands, and intentionally-optional Q4-10/Q4-01 best-effort calls). `nix flake check` passes.

### Phase 4 — Plugin system + independent helpers (parallel) ⬜

Plugin system:
- [x] ✅ **Plugin CLI** (Q4-01): shipped all 11 scripts in `pkgs/omanix-scripts/` — `omanix-plugin-{add,clone,enable,disable,update,remove,list,validate,catalog}`, `omanix-menu-plugin`, `omanix-git-url-check` — added `git`+`gum` as the only new deps. **Reconstructed from the IPC contract** (`shell.qml` `rescanPlugins`/`enablePlugin`/`setPluginEnabled`/`listPlugins`) + the `PluginRegistry.qml` manifest schema / `clonedFrom` routing, rather than mechanically porting; the two security scripts (`git-url-check` URL-refusal, `validate` schema) preserve upstream's exact semantics. omanix-tree adaptations: `notify-send` (best-effort) for `omarchy-notification-send`, `omanix-menu-dmenu` for `omarchy-menu-select`, `omanix-launch-tui` for the floating clone/remove terminal, `grep -rlZ -F` for the `rg` path-rewrite, `command -v delta` optional. User plugins → `~/.config/omanix/plugins/` (writable, created at runtime by the registry — R3, no Nix seeding); built-ins immutable in the store. `nix flake check` + `omanix-scripts` build pass; runtime paths verify on a live shell.

Independent CLI helpers (each self-contained; port as desired):
- [x] ✅ **Hardware detection** (Q4-02): shipped all 8 `omanix-hw-*` probes in `pkgs/omanix-scripts/` (reconstructed from the shell's call contract — upstream `bin/` was never vendored) plus the two power-panel data emitters `omanix-battery-status --shell` + `omanix-system-stats` (the other unimplemented Q1-13 followups, and the only in-repo callers besides `laptop-closed`; **scope call**: these read live sensor state Nix cannot declare, so they're inherently runtime scripts belonging here, not declarative — and nothing else owns them). Probes are pure sysfs/ACPI reads returning exit codes; `nvidia` reads cached PCI sysfs (never wakes a suspended GPU); `intel-sof` uses `lspci` (Q4-03 consumer); `webcam` delegates to `omanix-capture-webcam-list` with a `/sys/class/video4linux` fallback until **Q4-05** lands. Only new dep is `pciutils`. **isLaptop override:** new NixOS option `omanix.hardware.isLaptop` (`modules/nixos/hardware.nix`, nullable bool, default null = auto) wired into `omanix-hw-laptop` as `OMANIX_IS_LAPTOP` via the existing `osConfig`→`omanix-scripts.override` bridge in `modules/home-manager/scripts/default.nix` (same pattern as `scaledDesktop`); the runtime probe (ACPI lid / DMI chassis) stays the default. Scripts already reach the shell's PATH via `omanixScripts` in `home.packages` — no extra wiring. `nix build .#omanix-scripts` + `nix flake check` pass; per-host exit codes are runtime-only to verify.
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
