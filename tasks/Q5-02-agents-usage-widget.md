# Q5-02: Agents usage widget (Quickshell plugin + Python collectors)

- **Phase:** 5
- **Status:** done
- **Depends on:** Q1-05 (bar plugin host), Q4-01 (plugin CLI), Q5-01 (agent abstraction)
- **Blocks:** none
- **Size:** L

## Context
Omarchy 4.0.2 ships a bar widget (`omarchy.agents`, a Quickshell plugin) that shows AI
subscription usage: plan/hero, rate-limit meters with reset times, prepaid balance gauge, and
tokens by day/model. It self-hides when there is no usage data. It is fed by per-agent
collector scripts that write one display-ready JSON record per agent to
`~/.local/state/omarchy/agents/usage/<agent>.json`; the widget discovers agents purely from
those records (no per-agent widget code).

Three collectors ship, all **Python 3 stdlib-only** (portable as-is):
- `omarchy-agent-usage-claude` — Anthropic OAuth usage endpoint + local `~/.claude` transcripts.
- `omarchy-agent-usage-codex` — Codex CLI session files + Codex app-server RPC.
- `omarchy-agent-usage-fireworks` — Fireworks billing API + estimated prepaid balance.
An updater `omarchy-agent-usage-update` runs the collectors in parallel and writes the records.

## Scope
**In scope:** Port the `shell/plugins/agents/` Quickshell plugin (renamed to `omanix.agents`),
the three Python collectors, and the `omanix-agent-usage-update` orchestrator. Wire the widget
into the default bar layout, self-hiding when no records exist. State dir:
`~/.local/state/omanix/agents/usage/`.
**Out of scope:** agent launch (Q5-01), crash capture (Q5-03).

## Implementation notes
- **D1:** rename plugin id `omarchy.agents`→`omanix.agents`, IPC target likewise, `OMARCHY_PATH`
  →`OMANIX_PATH`, state dir `~/.local/state/omarchy/…`→`~/.local/state/omanix/…`, script names
  `omarchy-agent-usage-*`→`omanix-agent-usage-*`. Apply via the Q0-03 rename patch phase for the
  QML; the Python collectors are also renamed/patched.
- The plugin ships as part of the vendored `pkgs/omanix-shell` tree (Q1-02) — it lives under
  `shell/plugins/agents/`. Confirm it is present after vendoring; ship its `assets/*.svg`.
- **Collectors are stdlib-only Python 3** (sqlite3, urllib, fcntl, configparser, decimal) — no
  third-party deps. Package them (in `pkgs/omanix-scripts` or a dedicated derivation) with
  `python3` on PATH. They only reach external endpoints when the corresponding agent is
  actually in use (Anthropic OAuth usage, Codex app-server RPC subprocess, Fireworks billing).
  Fireworks config lives at `~/.config/omanix/agents/fireworks.json`.
- The widget runs `omanix-agent-usage-update` on a timer (`refreshIntervalSec`, default 900) and
  watches the records. Per-agent enable and cross-device sync settings live in the shell config
  (`shell.json` → `omanix.agents` settings). Scope enabled providers to agents omanix supports.
- Interactions to preserve: left-click = panel, right-click = `omanix-agent --pick`, middle =
  next subscription. These call Q5-01's launcher and the shell IPC.
- Only claude/codex/fireworks collectors exist upstream. Keep just the ones relevant to
  omanix's packaged agents; log a note for any dropped.

## Acceptance criteria
- [x] `omanix.agents` plugin loads in the shell and appears in the bar layout **when opt-in** (`omanix.apps.ai.usageWidget.enable`). Verified by eval: `bar.layout.right` gains `omanix.agents` (with a `providers` block + `refreshIntervalSec`) when enabled, and is unchanged when off.
- [ ] Widget self-hides when `~/.local/state/omanix/agents/usage/` has no records. *(runtime-only)*
- [x] `omanix-agent-usage-update` runs the collectors and writes one JSON record per agent atomically (`mktemp` + `mv`); discovery rewritten to PATH (D5). Bash `-n` parse passes.
- [x] Collectors run with only `python3` (stdlib) available; no third-party Python deps introduced. `py_compile` passes; runtime closure carries only `python3`.
- [ ] With a signed-in Claude, the widget shows plan + rate-limit meters after a refresh. *(runtime-only)*
- [ ] Left/right/middle-click behaviors work (panel / `omanix-agent --pick` / next). *(runtime-only; QML unchanged from upstream)*
- [x] No `omarchy`/`OMARCHY_PATH`/`omarchy.agents` strings remain in the ported plugin or collectors.
- [x] `nix flake check` passes; shell still builds; collector package builds.

## Testing
- `nix flake check`; build the shell package and the collector package.
- Runtime (Hyprland session): start the shell; with no records the widget is hidden. Create a
  dummy record `~/.local/state/omanix/agents/usage/claude.json` → widget appears.
- Run `omanix-agent-usage-update --force` and confirm records are (re)written.
- Grep ported plugin + collectors for `omarchy` → no matches.

## References
- omarchy: `shell/plugins/agents/{Main,Panel,Agent}.qml`, `manifest.json`, `assets/*.svg`, `README.md`; `bin/omarchy-agent-usage-{claude,codex,fireworks,update}`
- omanix: `pkgs/omanix-shell/` (vendored shell), `pkgs/omanix-scripts/`, `~/.config/omanix/shell.json`
