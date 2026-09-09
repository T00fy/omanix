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

    # AI subscription usage bar widget (omanix.agents Quickshell plugin) + its
    # Python usage collectors (Q5-02). Opt-in: off by default. The widget
    # self-hides per provider until a collector records usage, so a machine
    # with, say, only Claude signed in shows just Claude.
    usageWidget = {
      enable = lib.mkEnableOption "the AI agent usage bar widget and usage collectors";

      refreshIntervalSec = lib.mkOption {
        type = lib.types.ints.between 30 3600;
        default = 900;
        description = "How often the widget regenerates the usage records, in seconds.";
      };

      # Per-provider toggles. claude maps to the packaged claude-code; codex has
      # no packaged CLI (its collector self-skips when absent) and fireworks is a
      # provider opencode can run against — both default off. A disabled provider
      # is skipped by the widget and by the collector run.
      providers = {
        claude = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show Claude (Anthropic) usage in the widget.";
        };
        codex = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Show Codex usage in the widget (requires the codex CLI on PATH).";
        };
        fireworks = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Show Fireworks prepaid-balance and usage in the widget.";
        };
      };
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

    # --- Agent usage widget (Q5-02) ---
    # Ship the collectors + orchestrator; the omanix.agents plugin is wired into
    # the bar layout in quickshell.nix (which reads cfg.usageWidget). The widget
    # needs the shell, so warn if it is off. The claude collector already
    # surfaces opencode's Anthropic-provider sessions, so it is useful even when
    # only opencode is enabled.
    (lib.mkIf cfg.usageWidget.enable {
      home.packages = [ pkgs.omanix-agent-usage ];

      warnings = lib.optional (!config.omanix.quickshell.enable)
        "omanix.apps.ai.usageWidget.enable is set but omanix.quickshell.enable is false; the usage widget is a Quickshell bar plugin and will not appear.";
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
