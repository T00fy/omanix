# Waybar Configuration

Waybar is the status bar at the top of your screen.

## Available Options

Omanix exposes these options for easy customization:

```nix
omanix.waybar.modules-left = [ "hyprland/workspaces" ];

omanix.waybar.modules-center = [ "clock" ];

omanix.waybar.modules-right = [ 
  "tray" 
  "bluetooth" 
  "network" 
  "pulseaudio" 
  "battery" 
];
```

## Adding Custom Modules

In your flake, you can extend the defaults:

```nix
omanix.waybar.modules-right = [
  "cpu"
  "memory"  
  "tray"
  "bluetooth"
  "network"
  "pulseaudio"
  "battery"
];
```

## Overriding Module Config

```nix
programs.waybar.settings.mainBar.clock = lib.mkForce {
  format = "{:%H:%M:%S}";  # Add seconds
  interval = 1;
};
```

## Toggle Visibility

Use: `omanix-toggle-waybar` (bound to Super+Shift+Space)

## Documentation

https://github.com/Alexays/Waybar/wiki
