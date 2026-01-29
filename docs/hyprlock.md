# Hyprlock Configuration

Hyprlock is the lock screen for Hyprland.

## What's Configured

- **Background** - Uses your theme wallpaper with blur
- **Input field** - Centered, styled with theme colors
- **Clock** - Large time display above input
- **Date** - Day and date below clock

## Overriding in Your Flake

To change the clock format:

```nix
programs.hyprlock.settings.label = lib.mkForce [
  {
    text = "$TIME12";  # 12-hour format
    font_size = 100;
    position = "0, 150";
    halign = "center";
    valign = "center";
  }
];
```

To add a custom greeting:

```nix
programs.hyprlock.settings.label = lib.mkAfter [
  {
    text = "Welcome back!";
    position = "0, -100";
    halign = "center";
    valign = "center";
    font_size = 24;
  }
];
```

## Lock Screen Manually

Use: `omanix-lock-screen` (bound to Super+Ctrl+L)

## Documentation

https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/
