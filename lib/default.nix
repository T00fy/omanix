{ lib }:
let
  themes = import ./themes.nix;
  renderColorsToml = import ./theme-toml.nix { inherit lib; };
  renderShellToml = import ./shell-toml.nix { inherit lib; };
  renderPlymouthTheme = import ./plymouth.nix { inherit lib; };
  renderAgentTheme = import ./agent-theme.nix { inherit lib; };
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

  # Render a shell.toml (UI surface tokens) from a palette (see lib/shell-toml.nix).
  inherit renderShellToml;

  # Per-theme shell.toml strings, keyed by theme slug (Q2-03 writes these to the store).
  themesShellToml = lib.mapAttrs (_: t: renderShellToml { colors = t.colors; }) themes;

  # Render the palette-only coding-agent theme JSON (Claude Code + Pi) from a
  # palette (see lib/agent-theme.nix). Returns { claude, pi } JSON strings.
  inherit renderAgentTheme;

  # Per-theme agent theme JSON, keyed by theme slug — baked into the theme store
  # (quickshell.nix) so omanix-theme-set-{claude,pi} copy current/theme/{claude,pi}.json.
  themesClaudeJson = lib.mapAttrs (
    _: t: (renderAgentTheme { colors = t.colors; mode = t.meta.mode or "dark"; }).claude
  ) themes;
  themesPiJson = lib.mapAttrs (
    _: t: (renderAgentTheme { colors = t.colors; mode = t.meta.mode or "dark"; }).pi
  ) themes;

  # Render an omanix Plymouth "script"-module boot-splash theme from a palette
  # (see lib/plymouth.nix). Built declaratively per the active theme by
  # modules/nixos/plymouth.nix; no per-slug map is needed (single splash).
  inherit renderPlymouthTheme;

  # Expose dummyDisplay helpers (shared derivation logic between
  # modules/nixos/sunshine.nix and modules/home-manager/scripts/default.nix)
  dummyDisplay = import ./dummy-display.nix { inherit lib; };

  # Expose the runtime state-dir contract (single source of truth for
  # ~/.local/state/omanix; see docs/state-layout.md)
  state = import ./state.nix { inherit lib; };
}
