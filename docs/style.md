# Omanix Theming Guide

Omanix uses declarative theming through your NixOS configuration.
Unlike traditional Linux setups, themes are applied at build time.

## Available Themes

{{THEME_LIST}}

## How to Change Theme

1. Edit your flake.nix or home-manager configuration
2. Set the theme option:

```nix
omarchy.theme = "tokyo-night";
```

3. Rebuild your system:

```bash
sudo nixos-rebuild switch --flake .
```

## Customizing Wallpaper

You can override the wallpaper without changing themes:

```nix
omarchy.wallpaperOverride = ./path/to/wallpaper.jpg;
```

## Adding Custom Themes

To add a new theme, edit `lib/themes.nix` in your Omanix repo.
Each theme requires: meta, assets, bat config, and color palette.

See the tokyo-night theme as a reference.
