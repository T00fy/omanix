# Custom Wallpaper Override

You can override the active theme's wallpaper with any local image file on your disk.

## Instructions

1. Locate your image file (e.g., inside your repo or in `~/Pictures`).
2. Edit your `flake.nix` or Home Manager config.
3. Use the `wallpaperOverride` option:

```nix
omanix = {
  # The theme still determines colors, icons, and syntax highlighting
  theme = "tokyo-night";

  # This takes priority over 'wallpaperIndex'
  wallpaperOverride = ./path/to/your/image.jpg;
};
```

**Note:** If you reference a file inside your flake (e.g., `./assets/my-wall.jpg`), it will be copied to the Nix store and managed by git. If you point to an absolute path outside the flake, it may not work in pure mode.
