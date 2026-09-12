# Configuration Guide

All options live under the `omanix` namespace. This page shows common configuration patterns with examples.

For the complete list of every option with types and defaults, see the sidebar sections under **Options Reference**.

## Theme & Wallpaper

```nix
omanix = {
  theme = "tokyo-night";
  wallpaperIndex = 1;                    # Pick a different wallpaper from the theme
  wallpaperOverride = ./my-wallpaper.jpg; # Or use your own image entirely
};
```

## Monitor Setup

```nix
omanix = {
  monitor.scale = "1.25";    # Global scale (or "auto")

  # Multi-monitor workspace mapping
  monitors = [
    { name = "DP-2";     resolution = "2560x1440"; refreshRate = 144; }
    { name = "HDMI-A-2"; resolution = "2560x1440"; refreshRate = 144; }
  ];
};
```

Run `hyprctl monitors` to find your monitor names.

### Workspace model

`omanix.hyprland.uniqueWorkspacePerMonitor` selects how workspaces behave across
monitors. It defaults to `false`.

**`false` — shared workspaces (default, matches Omarchy).** One global set of
workspaces `1-5` shared across every monitor. `Super+N` focuses global workspace
`N` wherever you are — since a workspace lives on whichever monitor it was
created on, this jumps your focus to that monitor rather than dragging the
workspace to you. At session start monitor 1 holds workspace 1 and monitor 2
holds workspace 2, so `Super+1`/`Super+2` land on those monitors; workspaces 3-5
attach to the monitor you first summon them on. Every bar shows the same `1-5`
set and highlights the single focused workspace. To pull a workspace to the other
monitor with you, use `Super+Shift+Alt+←/→` (move workspace to left/right
monitor).

**`true` — unique workspace per monitor (legacy Omanix).** Each monitor gets its
own independent `1-5`, pinned to that output (real ids `10*monitorIndex + N`).
`Super+N` targets the focused monitor's Nth workspace, and each bar shows and
highlights only its own monitor's workspaces.

```nix
omanix.hyprland.uniqueWorkspacePerMonitor = true;
```

> Hyprland only re-reads workspace pinning on a fresh session (autoreload is
> disabled), so log out and back in after changing this option — a
> `nixos-rebuild` alone won't apply it to the running session.

## Hyprland Visuals

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
```

## Idle & Power Management

The Quickshell `omanix.idle` service is the single idle owner. Two stages,
each independently togglable with a configurable timeout:

```nix
omanix.idle = {
  screensaver = { enable = true; timeout = 150; };   # 2.5 min
  lock        = { enable = true; timeout = 900; };   # 15 min
};
```

There is no idle-dim, idle-DPMS-off, or auto-suspend-on-idle — the fullscreen
screensaver is the blanking, and locking before suspend is handled separately
(see [docs/idle.md](idle.md)). To keep the machine awake, use `omanix-toggle-idle`
(bound to `Super+Ctrl+I`, the "Stay Awake" menu entry, and the bar widget).

## Languages

Enable language toolchains and their LSPs for Neovim:

```nix
omanix.languages = {
  nix.enable = true;          # On by default
  markdown.enable = true;     # On by default
  rust.enable = true;
  go.enable = true;
  java.enable = true;
  docker.enable = true;
  terraform.enable = true;
  typescript.enable = true;
  tailwind.enable = true;
  json.enable = true;
  dart.enable = true;
  dotnet.enable = true;
};
```

## Optional Apps

All optional apps default to `false` — enable what you need:

```nix
omanix.apps = {
  neovim.enable = true;       # This one defaults to true
  jetbrains.intellij.enable = true;
  jetbrains.rustrover.enable = true;
  obsidian.enable = true;
  whatsapp.enable = true;
  spotify.enable = true;
  obs.enable = true;
  tmux.enable = true;
  gh.enable = true;
};
```

## Quickshell Bar

The desktop shell is Quickshell (`omanix.quickshell`, enabled by default). It
hosts the bar, launcher/menu, notifications, OSD, lock, clipboard, and
background — the old discrete-tool stack (waybar/walker/mako/hyprlock) has been
removed.

The bar layout is a list of widget-id entries per section; each entry is a bare
id string or `{ id = "..."; ...inline-settings }`:

```nix
omanix.quickshell.bar = {
  position = "top";                 # top | bottom | left | right
  transparent = false;
  clockFormat = "dddd HH:mm";       # Qt date tokens (not strftime)

  layout = {
    left = [
      { id = "omanix.menu"; }
      { id = "omanix.workspaces"; }
      { id = "omanix.active-window"; }
    ];
    center = [
      { id = "omanix.media"; }
      { id = "omanix.clock"; }
    ];
    right = [
      { id = "omanix.tray"; }
      { id = "omanix.bluetooth"; }
      { id = "omanix.network"; }
      { id = "omanix.audio"; }
      { id = "omanix.power"; }
    ];
  };
};
```

Third-party shell plugins are declared (and pinned) under
`omanix.quickshell.plugins`; nothing is fetched at runtime. See the
**Options Reference → Quickshell** section for the full option set.

## Extra Keybindings

Omanix drives Hyprland through its Lua config/IPC API, so keybindings use the
attrset / `mkLuaInline` form (key, `hl.*` dispatcher, options), and window rules
use a `match` block — not the legacy space-separated strings.

```nix
omanix.hyprland = {
  extraBindings = [
    {
      _args = [
        (lib.generators.mkLuaInline ''"SUPER + SHIFT + G"'')
        (lib.generators.mkLuaInline ''hl.dsp.exec_cmd([[gimp]])'')
        { description = "Open GIMP"; }
      ];
    }
  ];
  extraWindowRules = [
    { match = { class = "^(gimp)$"; }; opacity = "1.0 1.0"; }
  ];
  extraSettings = {
    # Any raw Hyprland setting
    general.allow_tearing = true;
  };
};
```

## System-Level Toggles

```nix
omanix = {
  enable = true;
  steam.enable = true;        # Steam + Gamescope + GameMode + MangoHud (default: true)
  docker.enable = true;       # Docker daemon + lazydocker (default: true)
  libreoffice.enable = true;  # LibreOffice (default: true)
  login.enable = true;        # SDDM with SilentSDDM theme (default: true)
  boot.plymouth.enable = true; # Theme-colored boot splash (default: true) — see below
};
```

## Boot Splash (Plymouth)

On by default (with `omanix.enable`). Builds a Plymouth boot splash colored from
the active `omanix.theme` (solid background + accent-colored progress bar) and
bakes it into the initrd. Disable it with:

```nix
omanix.boot.plymouth.enable = false;
```

This is fully declarative: the splash lives in the initrd, so it changes only on
`nixos-rebuild` — there is no runtime switcher. To change it, set a different
`omanix.theme` and rebuild.

The module adds the `quiet` and `splash` kernel params, but the bootloader is
host-provided: a compatible bootloader/initrd setup may be required for the
splash to actually appear.

## Gaming (Battle.net & RetroArch)

Optional, user-level gaming helpers (off by default). Steam is separate — see
`omanix.steam.enable` above.

```nix
omanix.gaming = {
  # Battle.net via umu-launcher + GE-Proton (no Steam/Lutris). Adds a
  # "Battle.net" desktop entry; run `omanix-gaming-battlenet install` once to
  # set up the prefix under ~/Games/battlenet.
  battlenet.enable = true;

  retroarch = {
    enable = true;
    # Libretro cores to bundle (attribute names under pkgs.libretro).
    # Omit to use the curated default set.
    cores = [
      "snes9x"
      "mgba"
      "mupen64plus"
      "beetle-psx-hw"
      "flycast"
    ];
  };
};
```

`omanix-games-retro-cores` lists the bundled cores with friendly labels, and
`omanix-games-retro-install <core> <rom>` (or interactive) writes a per-ROM
`.desktop` launcher to `~/.local/share/applications`.

## Security (SSH & Docker)

Omanix intentionally ships **no** `omanix.security.sshd` / `sudolessDocker` wrappers — on NixOS
these are already declarative stock options. Configure them directly.

### Harden SSH

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;       # key-only — authorize a key first (below)
    KbdInteractiveAuthentication = false;
  };
};

networking.firewall.allowedTCPPorts = [ 22 ];

users.users.<you>.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... you@host"          # paste your public key
];
```

Authorize a key **before** disabling password auth or you will lock yourself out. NixOS's
default firewall already drops unsolicited traffic — no `ufw limit` equivalent is needed.

### Passwordless Docker

Adding your user to the `docker` group grants **root-equivalent** access to the host: the
docker socket can bind-mount any path as root. Opt in only if you accept that.

```nix
users.users.<you>.extraGroups = [ "docker" ];   # convenient, root-equivalent
```

Otherwise leave it off and run privileged commands with `sudo docker`.

## Overriding Defaults

Omanix sets opinionated defaults, but everything can be overridden using standard NixOS/Home Manager patterns:

```nix
# Override a specific setting completely
wayland.windowManager.hyprland.settings.general.gaps_in = lib.mkForce 10;

# Append a keybinding (Lua bind format — see Extra Keybindings above)
wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
  {
    _args = [
      (lib.generators.mkLuaInline ''"SUPER + SHIFT + P"'')
      (lib.generators.mkLuaInline ''hl.dsp.exec_cmd([[my-custom-app]])'')
      { description = "My custom app"; }
    ];
  }
];

# Adjust idle timeouts
omanix.idle.screensaver.timeout = lib.mkForce 300;
omanix.idle.lock.timeout = lib.mkForce 1200;
```
