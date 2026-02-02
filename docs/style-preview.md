# Theme Preview: ${THEME_NAME}

You are currently previewing wallpaper **#${WP_INDEX}**.

To make this permanent, update your `flake.nix` or Home Manager config:

```nix
omanix = {
  theme = "${THEME_NAME}";
  # If 0, this line is optional
  wallpaperIndex = ${WP_INDEX};
};
```

**Next Steps:**

1. Edit your config.
2. Run your rebuild command (e.g., `rebuild`).
3. The preview will persist until you reboot or rebuild.
