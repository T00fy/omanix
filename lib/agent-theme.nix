{ lib }:

let
  inherit (import ./color-utils.nix { inherit lib; }) mix;
in

# Render the palette-only coding-agent theme files (Claude Code + Pi) from an
# omanix palette. Reproduces omarchy's default/themed/{claude,pi}.json.tpl.
# omanix's theme build only emits colors.toml + shell.toml, so these JSON
# sources are generated here and baked per-slug into the theme store
# (modules/home-manager/desktop/quickshell.nix); the runtime
# omanix-theme-set-{claude,pi} scripts then stay a faithful copy.
#
# `mix a b pct` is (100-pct)% of a + pct% of b, matching omarchy's
# `{{ mix a b pct% }}` direction exactly.
{
  colors,
  mode ? "dark",
}:

let
  # Semantic tokens → omanix palette. Matches lib/theme-toml.nix's mapping so
  # the agents agree with the rest of omanix theming (bright_foreground=cursor).
  accent = colors.accent;
  foreground = colors.foreground;
  background = colors.background;
  selection_background = colors.selection_background;
  selection_foreground = colors.selection_foreground;
  muted = colors.color8;

  red = colors.color1;
  green = colors.color2;
  yellow = colors.color3;
  blue = colors.color4;
  magenta = colors.color5;
  cyan = colors.color6;

  bright_red = colors.color9;
  bright_green = colors.color10;
  bright_yellow = colors.color11;
  bright_blue = colors.color12;
  bright_magenta = colors.color13;
  bright_cyan = colors.color14;
  bright_foreground = colors.cursor;

  claude = {
    name = "Omanix";
    base = mode; # theme_type: dark | light
    overrides = {
      claude = accent;
      claudeShimmer = mix accent foreground 35;
      text = foreground;
      inverseText = background;
      inactive = mix foreground background 40;
      inactiveShimmer = mix foreground background 25;
      subtle = muted;
      suggestion = cyan;
      permission = blue;
      permissionShimmer = mix blue foreground 35;
      remember = yellow;
      success = green;
      error = red;
      warning = yellow;
      warningShimmer = mix yellow foreground 35;
      merged = magenta;
      promptBorder = accent;
      promptBorderShimmer = mix accent foreground 35;
      planMode = cyan;
      autoAccept = yellow;
      bashBorder = bright_yellow;
      ide = bright_cyan;
      diffAdded = mix background green 15;
      diffRemoved = mix background red 15;
      diffAddedDimmed = mix background green 8;
      diffRemovedDimmed = mix background red 8;
      diffAddedWord = mix background green 32;
      diffRemovedWord = mix background red 32;
      userMessageBackground = mix background foreground 6;
      userMessageBackgroundHover = mix background foreground 10;
      bashMessageBackgroundColor = mix background foreground 6;
      memoryBackgroundColor = mix background foreground 6;
      selectionBg = selection_background;
      rate_limit_fill = accent;
      rate_limit_empty = mix background foreground 20;
      briefLabelYou = yellow;
      briefLabelClaude = accent;
    };
  };

  pi = {
    "$schema" = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = "omanix-system";
    vars = {
      inherit background foreground accent;
      selectionBackground = selection_background;
      selectionForeground = selection_foreground;
      selectedBackground = mix background accent 22;
      color0 = background;
      color1 = red;
      color2 = green;
      color3 = yellow;
      color4 = blue;
      color5 = magenta;
      color6 = cyan;
      color7 = foreground;
      color8 = muted;
      color9 = bright_red;
      color10 = bright_green;
      color11 = bright_yellow;
      color12 = bright_blue;
      color13 = bright_magenta;
      color14 = bright_cyan;
      color15 = bright_foreground;
      panel = mix background foreground 6;
      panelAlt = mix background foreground 10;
      panelPending = mix background accent 12;
      panelSuccess = mix background green 12;
      panelError = mix background red 12;
      border = mix background foreground 30;
      borderMuted = mix background foreground 20;
      mutedText = mix foreground background 34;
      dimText = mix foreground background 52;
    };
    # These reference var names (above), not hex — kept verbatim from upstream.
    colors = {
      accent = "accent";
      border = "border";
      borderAccent = "accent";
      borderMuted = "borderMuted";
      success = "color2";
      error = "color1";
      warning = "color3";
      muted = "mutedText";
      dim = "dimText";
      text = "foreground";
      thinkingText = "dimText";
      selectedBg = "selectedBackground";
      userMessageBg = "panel";
      userMessageText = "foreground";
      customMessageBg = "panel";
      customMessageText = "foreground";
      customMessageLabel = "accent";
      toolPendingBg = "panelPending";
      toolSuccessBg = "panelSuccess";
      toolErrorBg = "panelError";
      toolTitle = "accent";
      toolOutput = "foreground";
      mdHeading = "color5";
      mdLink = "accent";
      mdLinkUrl = "color6";
      mdCode = "color6";
      mdCodeBlock = "foreground";
      mdCodeBlockBorder = "borderMuted";
      mdQuote = "mutedText";
      mdQuoteBorder = "borderMuted";
      mdHr = "borderMuted";
      mdListBullet = "color5";
      toolDiffAdded = "color2";
      toolDiffRemoved = "color1";
      toolDiffContext = "mutedText";
      syntaxComment = "dimText";
      syntaxKeyword = "color5";
      syntaxFunction = "color4";
      syntaxVariable = "accent";
      syntaxString = "color2";
      syntaxNumber = "color3";
      syntaxType = "color4";
      syntaxOperator = "color5";
      syntaxPunctuation = "mutedText";
      thinkingOff = "borderMuted";
      thinkingMinimal = "accent";
      thinkingLow = "color4";
      thinkingMedium = "color5";
      thinkingHigh = "color3";
      thinkingXhigh = "color1";
      bashMode = "color3";
    };
    export = {
      pageBg = background;
      cardBg = mix background foreground 6;
      infoBg = mix background foreground 10;
    };
  };
in
{
  claude = builtins.toJSON claude;
  pi = builtins.toJSON pi;
}
