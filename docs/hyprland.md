# Hyprland Configuration

Omanix splits Hyprland config into logical modules:

## Module Files

- `autostart.nix` - Programs launched on login
- `bindings.nix` - Keyboard shortcuts  
- `envs.nix` - Environment variables
- `input.nix` - Keyboard/mouse/touchpad settings
- `monitors.nix` - Multi-monitor workspace bindings
- `rules.nix` - Window rules (floating, opacity, etc)
- `visuals.nix` - Gaps, borders, animations, blur

## Available Options

```nix
# Display
omanix.monitor.scale = "1.5";

# Multi-monitor workspace bindings
omanix.monitors = [
  { name = "DP-2"; workspaces = [ 1 2 3 4 5 ]; }
  { name = "HDMI-A-1"; workspaces = [ 6 7 8 9 10 ]; }
];

# Gaps
omanix.hyprland.gaps.inner = 5;      # Between windows
omanix.hyprland.gaps.outer = 10;     # Screen edges

# Borders
omanix.hyprland.border.size = 2;

# Rounding
omanix.hyprland.rounding = 0;        # Corner radius

# Blur
omanix.hyprland.blur.enabled = true;
omanix.hyprland.blur.size = 2;
omanix.hyprland.blur.passes = 2;

# Shadows
omanix.hyprland.shadow.enabled = true;
omanix.hyprland.shadow.range = 2;

# Animations
omanix.hyprland.animations.enabled = true;
```

## Overriding in Your Flake

To add custom keybindings:

```nix
wayland.windowManager.hyprland.settings.bind = lib.mkAfter [
  "$mainMod SHIFT, P, exec, my-custom-app"
];
```

To override settings completely:

```nix
wayland.windowManager.hyprland.settings.general.gaps_in = lib.mkForce 10;
```

## Finding Monitor Names

Run: `hyprctl monitors`

## Documentation

https://wiki.hyprland.org/Configuring/
