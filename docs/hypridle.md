# Hypridle Configuration

Hypridle manages automatic screen locking and power saving.

## Default Timeouts

| Time    | Action                      |
|---------|----------------------------|
| 2.5 min | Screen dims to 10%         |
| 5 min   | Screen locks (hyprlock)    |
| 5.5 min | Display turns off          |
| 15 min  | System suspends            |

## Overriding in Your Flake

To change timeouts:

```nix
services.hypridle.settings.listener = lib.mkForce [
  {
    timeout = 300;  # 5 minutes
    on-timeout = "brightnessctl -s set 10";
    on-resume = "brightnessctl -r";
  }
  {
    timeout = 600;  # 10 minutes  
    on-timeout = "loginctl lock-session";
  }
];
```

To disable suspend entirely, omit the suspend listener from your override.

## Temporarily Disable

Use: `omarchy-toggle-idle` (bound to Super+Ctrl+I)

## Documentation

https://wiki.hyprland.org/Hypr-Ecosystem/hypridle/
