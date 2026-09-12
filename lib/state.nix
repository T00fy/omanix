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

  # Shell-expandable string for the per-user state root. Written with an
  # escaped `$` so Nix does NOT interpolate `$HOME` — the literal expression
  # is emitted for a shell to expand at runtime. Use verbatim inside bash /
  # home.activation scripts so every consumer resolves the same directory.
  #
  # This is deliberately HOME-based rather than XDG_STATE_HOME-based: the
  # vendored QML reads its state from `$HOME/.local/state/omanix` (only
  # plugins/agents/Main.qml honors XDG_STATE_HOME today). The shell's read
  # path is therefore the source of truth, and the write side (activation +
  # scripts) must match it — honoring XDG_STATE_HOME on the write side alone
  # would point writes at a directory the shell never reads. When the QML is
  # reconciled to honor XDG_STATE_HOME, flip this one expression to
  # `''${XDG_STATE_HOME:-$HOME/.local/state}/omanix` and every consumer moves
  # with it. See docs/state-layout.md.
  rootExpr = ''$HOME/.local/state/omanix'';

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
