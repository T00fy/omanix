# Runtime state directory layout (`~/.local/state/omanix/`)

This is the canonical contract for omanix's **mutable per-user runtime state** — the data that
is *not* declarative and must survive across shell restarts (active theme, toggle flags, agent
usage, notification history, …). It is established by ticket **Q0-04** and consumed by later
tickets (Q2-03/04 theming, Q5-02 agents, Q1-06 notifications, Q1-12 idle, …).

Upstream omarchy uses `~/.local/state/omarchy/`; per decision **D1** omanix uses
`~/.local/state/omanix/`.

## Resolver contract

The state root is **always**:

```
${XDG_STATE_HOME:-$HOME/.local/state}/omanix
```

- **Nix code** uses the single source of truth `omanixLib.state.rootExpr` (defined in
  `lib/state.nix`, surfaced via `lib/default.nix`). Subpath names live in
  `omanixLib.state.subdirs`.
- **Bash / activation scripts** use the same idiom inline:
  `"${XDG_STATE_HOME:-$HOME/.local/state}/omanix"`. There is deliberately **no** shared bash
  library to source (the repo has no such mechanism); the idiom is short and self-contained.

The base directory is created writable on activation by
`modules/home-manager/core/state.nix` (a plain `home.activation` `mkdir -p`). Feature
subdirectories are **not** pre-created — each feature `mkdir -p`s the subdir it owns as it
lands.

## Ownership rule (declarative vs runtime — D2 / R3)

- **Declarative config is the source of truth.** The declared `omanix.*` options (e.g.
  `omanix.theme`) are (re)applied on every rebuild / activation.
- **Runtime tools may overlay ephemeral changes here** — e.g. `omanix-theme-set`, toggle
  scripts, or the Quickshell shell over IPC. These are **ephemeral overlays**: a rebuild or
  shell restart reverts to the declared state.
- **Therefore state files must be created/seeded by activation (`mkdir` / copy), never
  symlinked into the immutable Nix store** — they must be writable. See risk **R3** and
  decision **D2** in [`../PORTING-QUATTRO.md`](../PORTING-QUATTRO.md).

## Canonical layout

Reflects what the vendored Quickshell tree (`vendor/omanix-shell/`) and the ported scripts
actually read/write. Only the base root is created up front; everything below is created by its
owning feature.

```
~/.local/state/omanix/
├── current/                       active theme + background (theme tickets)
│   ├── theme/                     generated active theme dir
│   │   ├── colors.toml            (Commons/Color.qml)
│   │   ├── shell.toml             (Commons/Color.qml)
│   │   └── backgrounds/           wallpaper pool (image-picker default dir)
│   ├── theme.name                 selected theme slug (bash-side pointer)
│   └── background                 symlink → active wallpaper
├── toggles/                       flag files — presence = state
│   ├── bar-off                    (plugins/bar/Bar.qml)
│   ├── crash-capture-off          gates the crash-watch service (Q5-03)
│   ├── screensaver-off, suspend-off, …
│   └── hypr/
│       └── window-no-gaps.lua     (Commons/Style.qml), flags.lua, …
├── agents/
│   └── usage/<agent>.json         usage records, atomic write (plugins/agents/Main.qml)
├── notifications.json             { version, dnd } — the DND preference lives HERE
├── notifications/                 live on-screen popups (plugins/notifications/Service.qml)
│   ├── history/                   expired / dismissed
│   └── images/                    persisted notification images
├── indicators/
│   └── stay-awake                 (plugins/services/idle/Service.qml)
├── settings/
│   └── weather.json               (plugins/panels/weather/Panel.qml)
└── clipboard-history.json         (plugins/clipboard/Clipboard.qml, clipboard/capture.sh)
```

### Notes / corrections

- **There is no `toggles/dnd`.** Do-Not-Disturb is a `dnd` boolean inside
  `notifications.json` — not a toggle flag file. (The Q0-04 ticket's early enumeration listed
  `dnd` under `toggles/`; that was wrong.)
- `crash-capture-off` is a `toggles/` flag; `stay-awake` lives at `indicators/stay-awake`.
- Existing omanix scripts (`omanix-toggle-idle`, `omanix-scale`, `omanix-theme-bg-next`, …)
  keep **ephemeral** state under `$XDG_RUNTIME_DIR/omanix-*`, which is intentionally *not* this
  persistent tree and is out of scope for the state contract.

## Known gap — `XDG_STATE_HOME` consistency

The vendored QML honors `XDG_STATE_HOME` **inconsistently**: only
`vendor/omanix-shell/plugins/agents/Main.qml` respects it; the rest hardcode
`$HOME/.local/state`. If a user overrides `XDG_STATE_HOME` to a non-default location, the shell
and the scripts may disagree on the state root. Reconciling the vendored QML to honor
`XDG_STATE_HOME` uniformly is deferred to **Q1-02** (shell packaging), the next ticket that
touches the vendored tree. The resolver defined here honors `XDG_STATE_HOME`; the default
(`$HOME/.local/state`) matches the QML today.
