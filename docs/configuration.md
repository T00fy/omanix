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

Each monitor gets its own set of workspaces. `Super+1-5` targets the focused monitor's workspaces. Run `hyprctl monitors` to find your monitor names.

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

Every stage is independently togglable and has a configurable timeout:

```nix
omanix.idle = {
  screensaver = { enable = true; timeout = 150; };   # 2.5 min
  dimScreen   = { enable = true; timeout = 840; brightness = 10; };
  lock        = { enable = true; timeout = 900; };   # 15 min
  dpms        = { enable = true; timeout = 960; };
  suspend     = { enable = true; timeout = 1800; };  # 30 min
};
```

To disable suspend entirely: `omanix.idle.suspend.enable = false;`

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

## Waybar

```nix
omanix.waybar = {
  modules-left = [ "hyprland/workspaces" ];
  modules-center = [ "clock" ];
  modules-right = [
    "cpu" "memory"
    "tray" "bluetooth" "network" "pulseaudio" "battery"
  ];

  # Configure any module
  extraModuleSettings = {
    clock = { format = "{:%H:%M:%S}"; interval = 1; };
  };

  # Append custom CSS (theme variables @background, @foreground, @accent are available)
  extraStyle = ''
    #cpu { color: @accent; margin: 0 8px; }
  '';
};
```

## Extra Keybindings

```nix
omanix.hyprland = {
  extraBindings = [
    "$mainMod SHIFT, G, Open GIMP, exec, gimp"
  ];
  extraWindowRules = [
    "opacity 1 1, match:class ^(gimp)$"
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
};
```

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

# Append to a list
wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
  "$mainMod SHIFT, P, exec, my-custom-app"
];

# Override hypridle listeners
services.hypridle.settings.listener = lib.mkForce [ /* your config */ ];
```
