# Hyprland Configuration

Omanix splits Hyprland config into logical modules:

## Module Files

- `autostart.nix` - Programs launched on login
- `bindings.nix` - Keyboard shortcuts
- `envs.nix` - Environment variables
- `input.nix` - Keyboard/mouse/touchpad settings
- `monitors.nix` - Monitor layout and the workspace model
- `rules.nix` - Window/layer rules (floating, opacity, etc)
- `visuals.nix` - Gaps, borders, animations, blur

> Omanix drives Hyprland through its **Lua config/IPC API** (`hl.*`), not the
> legacy space-separated string syntax. The examples below use the attrset /
> `mkLuaInline` forms the modules expect; legacy string binds/rules
> (`"$mod, Q, exec, app"`) are evaluated as Lua and fail silently.

## Monitors & workspaces

```nix
omanix.monitors = [
  { name = "DP-1";     resolution = "2560x1440"; refreshRate = 144; position = "0x0"; }
  { name = "HDMI-A-2"; resolution = "2560x1440"; refreshRate = 144; position = "2560x0"; }
];
```

Each monitor entry accepts `name` (required), and optional `resolution`,
`refreshRate`, `position`, `workspaceCount` (default `5`), and `disabled`. Fields
left unset fall through to Hyprland's preferred mode / auto position. Run
`hyprctl monitors` to find your monitor names.

### Workspace model

`omanix.hyprland.uniqueWorkspacePerMonitor` (bool, default `false`) selects how
workspaces behave across monitors:

- **`false` — shared workspaces (default, matches Omarchy):** one global set of
  workspaces `1-5` shared across every monitor. `Super+N` focuses global
  workspace `N` wherever you are, jumping focus to whichever monitor holds it.
- **`true` — unique workspace per monitor (legacy Omanix):** each monitor gets
  its own independent `1-5`, pinned to that output (real ids `10*monitorIndex + N`).
  `Super+N` targets the focused monitor's Nth workspace.

Hyprland only re-reads workspace pinning on a fresh session (autoreload is
disabled), so log out and back in after changing this — a `nixos-rebuild` alone
won't apply it to the running session. See the
[Configuration Guide](configuration.md#workspace-model) for the full write-up.

## Visuals

```nix
omanix.hyprland = {
  gaps.inner = 5;           # Between windows
  gaps.outer = 10;          # Screen edges
  border.size = 2;
  rounding = 0;             # Corner radius

  blur.enabled = true;
  blur.size = 2;
  blur.passes = 2;

  shadow.enabled = true;
  shadow.range = 2;

  animations.enabled = true;
};

omanix.monitor.scale = "1.5";   # Global scale (or "auto")
```

## Extra keybindings and rules

`extraBindings` takes the Lua bind format — an attrset whose `_args` are the key,
the `hl.*` dispatcher, and an options attrset (both wrapped with
`lib.generators.mkLuaInline`):

```nix
omanix.hyprland.extraBindings = [
  {
    _args = [
      (lib.generators.mkLuaInline ''"SUPER + SHIFT + G"'')
      (lib.generators.mkLuaInline ''hl.dsp.exec_cmd([[gimp]])'')
      { description = "Open GIMP"; }
    ];
  }
];
```

Window and layer rules use the attrset form with a `match` block:

```nix
omanix.hyprland.extraWindowRules = [
  { match = { class = "^(gimp)$"; }; opacity = "1.0 1.0"; }
];

omanix.hyprland.extraLayerRules = [
  { match = { namespace = "my-layer"; }; blur = true; }
];
```

For raw Hyprland settings not covered by an option, use `extraSettings`:

```nix
omanix.hyprland.extraSettings = {
  general.allow_tearing = true;
};
```

## Overriding defaults

Anything Omanix sets can be overridden with standard Home Manager patterns:

```nix
# Override a specific setting
wayland.windowManager.hyprland.settings.general.gaps_in = lib.mkForce 10;
```

## Options reference

Every `omanix.hyprland.*` and `omanix.monitors` option — with types, defaults,
and examples — is generated from the modules and lives under **Options
Reference → Hyprland** and **→ Monitors** in the sidebar.

## Upstream

https://wiki.hyprland.org/Configuring/
