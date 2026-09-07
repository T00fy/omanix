{ lib }:
let
  themes = import ./themes.nix;
  renderColorsToml = import ./theme-toml.nix { inherit lib; };
in
{
  # Expose color utils
  colors = import ./color-utils.nix { inherit lib; };

  # Expose themes (data only, doesn't need lib)
  inherit themes;

  # Render an omarchy-format colors.toml from a palette (see lib/theme-toml.nix).
  inherit renderColorsToml;

  # Per-theme colors.toml strings, keyed by theme slug (Q2-03 writes these to the store).
  themesColorsToml = lib.mapAttrs (
    _: t: renderColorsToml { colors = t.colors; mode = t.meta.mode or "dark"; }
  ) themes;

  # Expose dummyDisplay helpers (shared derivation logic between
  # modules/nixos/sunshine.nix and modules/home-manager/scripts/default.nix)
  dummyDisplay = import ./dummy-display.nix { inherit lib; };

  # Expose the runtime state-dir contract (single source of truth for
  # ~/.local/state/omanix; see docs/state-layout.md)
  state = import ./state.nix { inherit lib; };
}
