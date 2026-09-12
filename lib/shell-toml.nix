{ lib }:

let
  inherit (import ./color-utils.nix { inherit lib; }) mix shellGradient;
in

# Render the shell.toml surface tokens the Quickshell shell consumes, from an
# omanix palette. Ported from omarchy's default/themed/shell.toml.tpl (13
# sections). Non-color keys are constants; only color-valued keys derive from
# the palette. Explanatory comments live here, not in the emitted store file.
{
  colors,
  # Optional Hyprland-style gradient for the active border, as
  # { colors = [ "rgba(..)" .. ]; angle ? null; }. null (the default, and both
  # shipped themes) falls back to a solid accent/foreground border, matching
  # omanix's solid rgb(accent) Hyprland border in visuals.nix.
  hyprlandActiveBorder ? null,
  # Declared shell font base-size in px (omanix.monitor.textSize). The Display
  # panel's Text Size slider overlays this at runtime via
  # ~/.config/omanix/shell.toml; a rebuild re-asserts this declared value.
  baseSize ? 12,
}:

let
  inherit (colors) background foreground accent;
  red = colors.color1;

  # [hyprland] active-border / active-border-foreground: use the theme gradient
  # if provided, else the fallback solid color (omarchy shell_gradient fallback).
  activeBorder = shellGradient {
    spec = hyprlandActiveBorder;
    fallback = accent;
  };
  activeBorderForeground = shellGradient {
    spec = hyprlandActiveBorder;
    fallback = foreground;
  };

  # [lock] placeholder = mix foreground background 34%
  lockPlaceholder = mix foreground background 34;
in
''
  [bar]
  background       = "${background}"
  background-alpha = 1.0
  text             = "${foreground}"
  active           = "${red}"
  scale-with-font  = true
  size-horizontal  = 26
  size-vertical    = 28

  [hyprland]
  active-border            = "${activeBorder}"
  active-border-foreground = "${activeBorderForeground}"

  [controls]
  normal-color        = "${foreground}"
  normal-fill-alpha   = 0.04
  normal-border       = "${foreground}"
  normal-border-width = 1
  normal-border-alpha = 0.4

  hover-cursor-color        = "${foreground}"
  hover-cursor-fill-alpha   = 0.08
  hover-cursor-border       = "${foreground}"
  hover-cursor-border-width = 1
  hover-cursor-border-alpha = 0.25

  focus-color        = "${foreground}"
  focus-fill-alpha   = 0.08
  focus-border       = "${foreground}"
  focus-border-width = 1
  focus-border-alpha = 0.25

  selected-color        = "${foreground}"
  selected-fill-alpha   = 0.18
  selected-border       = "${foreground}"
  selected-border-width = 0
  selected-border-alpha = 1.0

  pressed-fill-alpha   = 0.22
  selection-fill-alpha = 0.35

  [spacing]
  scale = 1.0
  scale-with-font = true

  [font]
  base-size = ${toString baseSize}

  [popups]
  background       = "${background}"
  background-alpha = 1.0
  text             = "${foreground}"
  border           = "hyprland.active-border"
  border-alpha     = 1.0

  [tooltip]
  background       = "${background}"
  background-alpha = 0.97
  text             = "${foreground}"
  border           = "hyprland.active-border-foreground"
  border-alpha     = 1.0

  [notifications]
  background       = "${background}"
  background-alpha = 1.0
  text             = "${foreground}"
  border           = "hyprland.active-border"
  border-alpha     = 1.0
  countdown        = "${accent}"

  [launcher]
  background                = "${background}"
  background-alpha          = 0.95
  text                      = "${foreground}"
  border                    = "hyprland.active-border-foreground"
  border-alpha              = 1.0
  scrim                     = "${background}"
  scrim-alpha               = 0.5
  selected-background       = "${foreground}"
  selected-background-alpha = 0.08
  selected-text             = "${accent}"
  selected-border           = "hyprland.active-border-foreground"
  selected-border-alpha     = 0.25

  [menu]
  background                = "${background}"
  background-alpha          = 1.0
  text                      = "${foreground}"
  border                    = "hyprland.active-border-foreground"
  border-alpha              = 1.0
  scrim                     = "${background}"
  scrim-alpha               = 0.5
  selected-background       = "${foreground}"
  selected-background-alpha = 0.08
  selected-text             = "${accent}"
  selected-border           = "hyprland.active-border-foreground"
  selected-border-alpha     = 0.25

  [polkit]
  background       = "${background}"
  background-alpha = 1.0
  text             = "${foreground}"
  text-error       = "${red}"
  border           = "hyprland.active-border"
  border-error     = "${red}"
  border-alpha     = 1.0
  scrim            = "${background}"
  scrim-alpha      = 0.5
  accent           = "${accent}"

  [lock]
  background       = "${background}"
  background-alpha = 0.8
  text             = "${foreground}"
  placeholder      = "${lockPlaceholder}"
  text-error       = "${red}"
  border           = "hyprland.active-border"
  border-active    = "hyprland.active-border"
  border-error     = "${red}"
  border-alpha     = 1.0
  selection        = "${accent}"
  selection-alpha  = 0.45

  [image-picker]
  scrim                   = "${background}"
  scrim-alpha             = 0.5
  text                    = "${foreground}"
  selected-border         = "${accent}"
  selected-border-alpha   = 1.0
  unselected-border       = "${foreground}"
  unselected-border-alpha = 0.28
''
