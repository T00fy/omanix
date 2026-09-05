{ lib }:
rec {
  # ═══════════════════════════════════════════════════════════════════
  # Runtime state directory contract for omanix.
  #
  # See docs/state-layout.md for the full canonical layout and the
  # declarative-vs-runtime ownership rule (decision D2 / risk R3 in
  # PORTING-QUATTRO.md). This file is the single source of truth for the
  # state root path so Nix modules, activation scripts, and (future)
  # ported omanix-* scripts never drift.
  # ═══════════════════════════════════════════════════════════════════

  # Shell-expandable string for the per-user state root; honors
  # XDG_STATE_HOME. Written with escaped `$` so Nix does NOT interpolate
  # `$XDG_STATE_HOME` / `$HOME` — the literal expression is emitted for a
  # shell to expand at runtime. Use verbatim inside bash / home.activation
  # scripts. This mirrors the idiom already in the vendored shell
  # (vendor/omanix-shell/plugins/clipboard/capture.sh).
  #
  # Known gap: most of the vendored QML hardcodes `$HOME/.local/state`
  # (only plugins/agents/Main.qml honors XDG_STATE_HOME). Reconciling the
  # QML is deferred to Q1-02. See docs/state-layout.md.
  rootExpr = ''''${XDG_STATE_HOME:-$HOME/.local/state}/omanix'';

  # Canonical subpath names, so future tickets reference one source
  # instead of scattering string literals. Not pre-created on activation —
  # each feature `mkdir -p`s the subdir it needs when it lands.
  subdirs = {
    current = "current"; # active theme dir + background symlink (Q2-03/04)
    toggles = "toggles"; # flag files: bar-off, crash-capture-off, hypr/*.lua …
    agentsUsage = "agents/usage"; # <agent>.json usage records (Q5-02)
    notifications = "notifications"; # popups + history/ + images/ (notifications.json sits alongside)
    indicators = "indicators"; # stay-awake (Q1-12 idle)
    settings = "settings"; # weather.json …
  };
}
