# Omanix Theming Guide

Omanix uses declarative theming through your NixOS configuration.
Unlike traditional Linux setups, themes are applied at build time.

## Available Themes

{{THEME_LIST}}

## How to Change Theme

1. Edit your `flake.nix` or home-manager configuration.
2. Set the theme option:

```nix
omanix.theme = "tokyo-night";
```

3. Rebuild your system:

```bash
sudo nixos-rebuild switch --flake .
```

## Changing the Wallpaper

Themes include curated wallpapers. You can select which one to use by index (starting at 0).

```nix
omanix = {
  theme = "tokyo-night";
  wallpaperIndex = 1; # Selects the second wallpaper
};
```

*Use the **Style** menu (`Super+Alt+Space` -> Style) to preview wallpapers and find their index.*

## Custom Wallpaper Override

You can ignore the theme's wallpaper entirely and use your own local file.
See the **Custom Override** section in the Style menu, or read `docs/style-override.md`.

## Adding Custom Themes

To add a new theme, edit `lib/themes.nix` in your Omanix repo.
Each theme requires: meta, assets (list of wallpapers), bat config, and color palette.
