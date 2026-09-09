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

    # Declarative default coding agent (source of truth, reconciled onto
    # ~/.config/omanix/defaults/agent each activation — D2). The enum is the
    # eval-time assertion; keep it in lockstep with omanix-agent's map and the
    # omanix-menu.jsonc picker. null = unset (nothing launches until picked).
    defaultAgent = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [
        "claude"
        "opencode"
      ]);
      default = null;
      description = "The default coding agent launched by omanix-agent.";
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

    # --- Default agent (declarative source of truth, D2) ---
    # Reconcile the declared default onto the picker-writable
    # ~/.config/omanix/defaults/agent each activation (declared wins; a runtime
    # `omanix-agent --pick` change is reverted on the next rebuild). Written as a
    # copy, never a store symlink (R3). When defaultAgent = null this block is
    # inert and any existing runtime pick is left untouched.
    (lib.mkIf (cfg.defaultAgent != null) {
      home.activation.omanixDefaultAgent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "$HOME/.config/omanix/defaults"
        _omanix_agent="$HOME/.config/omanix/defaults/agent"
        run printf '%s\n' ${lib.escapeShellArg cfg.defaultAgent} > "$_omanix_agent.tmp"
        run mv "$_omanix_agent.tmp" "$_omanix_agent"
      '';

      warnings = lib.optional (
        (cfg.defaultAgent == "claude" && !cfg.claudeCode.enable)
        || (cfg.defaultAgent == "opencode" && !cfg.openCode.enable)
      ) "omanix.apps.ai.defaultAgent is \"${cfg.defaultAgent}\" but its agent is not enabled; omanix-agent will report it as unavailable until you enable the matching omanix.apps.ai.*.enable option.";
    })
  ];
}
