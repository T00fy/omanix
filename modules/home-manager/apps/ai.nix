{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omanix.apps.ai;
in
{
  options.omanix.apps.ai = {
    claudeCode = {
      enable = lib.mkEnableOption "Claude Code CLI";

      disableTelemetry = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Disable Claude Code telemetry via environment variables";
      };

      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Declarative configuration to write to ~/.claude.json";
      };
    };

    openCode = {
      enable = lib.mkEnableOption "Open Code CLI";
    };
  };

  config = lib.mkMerge [
    # --- Claude Code Configuration ---
    (lib.mkIf cfg.claudeCode.enable {
      home = {
        packages = [ pkgs.llm-agents.claude-code ];

        # Disable telemetry declaratively if requested
        sessionVariables = lib.mkIf cfg.claudeCode.disableTelemetry {
          CLAUDE_TELEMETRY = "0";
        };

        # Write configuration file if settings are provided
        file.".claude.json" = lib.mkIf (cfg.claudeCode.settings != { }) {
          text = builtins.toJSON cfg.claudeCode.settings;
        };
      };

      # Auto-activate the Omanix palette theme in Claude Code. Copies
      # the declared theme's claude.json to ~/.claude/themes/omanix.json and
      # sets settings.theme = "custom:omanix". Ordered after omanixThemeState so
      # current/theme (the source) is seeded first; ~/.claude/settings.json is
      # jq-merged in place (user-writable, never a store symlink — R3).
      # Best-effort: never fails activation, and no-ops if the theme source
      # isn't seeded (e.g. omanix.quickshell.enable = false).
      home.activation.omanixClaudeTheme = lib.hm.dag.entryAfter [
        "writeBoundary"
        "omanixThemeState"
      ] ''
        run ${config.omanix.scripts.package}/bin/omanix-theme-set-claude --activate || true
      '';
    })

    # --- Open Code Configuration ---
    (lib.mkIf cfg.openCode.enable {
      home.packages = [ pkgs.llm-agents.opencode ];
    })
  ];
}
