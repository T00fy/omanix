# Q5-01: `omanix-agent` launcher + `omanix-default-agent` picker

- **Phase:** 5
- **Status:** done
- **Depends on:** Q1-08 (menu plugin, for the picker surface), D3
- **Blocks:** Q5-02, Q5-03, Q5-04
- **Size:** M

## Context
Omarchy 4.0.2 added a generic coding-agent abstraction: one command launches whichever CLI
agent the user selected as default, in a standardized terminal window, in unattended
auto-approve mode. Two scripts drive it:

- `omarchy-agent` — reads the default agent, then launches it (fixed window app-id
  `org.omarchy.agent` so window rules/themes target every agent window). `--inline` runs in
  the current terminal; `--pick` opens the picker menu; `--prompt "…"` forwards a prompt. Each
  agent has a hardcoded "don't stop to ask" invocation (e.g. `claude --permission-mode auto`,
  `opencode --auto`, `codex --approve-for-me`, `gemini`/`pi` plain).
- `omarchy-default-agent` — reads/sets the default at `~/.config/omarchy/defaults/agent`.
  Maps friendly name → agent id → **mise package**, runs `mise use -g <pkg>`, launches. Ships
  **no default** (empty = nothing launches; menu shows all entries unchecked).

Omanix has no agent launcher today. It installs `pkgs.llm-agents.claude-code` and
`.opencode` opt-in via `modules/home-manager/apps/ai.nix`.

## Scope
**In scope:** Port `omanix-agent` and `omanix-default-agent` scripts (packaged in
`pkgs/omanix-scripts`), the friendly-name↔id↔auto-approve-flag mapping, the fixed app-id
launch, a declarative `omanix.apps.ai.defaultAgent` option reconciled onto
`~/.config/omanix/defaults/agent` (source of truth; runtime picker is an ephemeral overlay), and
the menu picker entry (Setup › Defaults › Agent). Scope the agent set to what is **actually packaged** via
`llm-agents` (at minimum `claude`, `opencode`), not all ~15 upstream agents.
**Out of scope:** usage widget (Q5-02), crash capture (Q5-03), skills (Q5-04), mise.

## Implementation notes
- **D3 divergence (critical):** replace the mise install path entirely. `omarchy-default-agent`
  does `mise where`/`mise use -g <package>` and, when missing, relaunches with `--install`.
  In omanix there is no per-user install step: an agent is "available" iff its `llm-agents`
  package is installed by the user's config. So:
  - Enumerate the agents omanix supports from a static map keyed on what `pkgs.llm-agents`
    exposes. Verify the attr set at build time: `nix eval --raw <llm-agents>#packages... ` or
    inspect the input; **do not** hardcode agents that aren't packaged.
  - Presence check becomes a plain `command -v <agent-bin>` (the binary is on PATH when the
    HM option is enabled) instead of `mise where`. Drop the `--install` re-launch branch.
  - Setting a default just writes `~/.config/omanix/defaults/agent`; it does **not** install
    anything. If the chosen agent's binary is absent, the picker/launcher tells the user which
    `omanix.apps.ai.*.enable` option to turn on (guides to declarative config, not an imperative install).
- **Declarative default (source of truth), mirroring D2/Q1-03:** add an
  `omanix.apps.ai.defaultAgent` option (nullable string; default `null` = unset, preserving
  upstream's "no default → nothing launches"). When set, its value is the **source of truth** for
  the default agent and is **reconciled onto `~/.config/omanix/defaults/agent` on every
  activation** (copy — the file is picker-writable, never a store symlink; declared value wins). An
  eval-time assertion should reject a `defaultAgent` that isn't in the supported/packaged set. The
  runtime `omanix-default-agent <id>` / `omanix-agent --pick` write the same file as an **ephemeral
  overlay**: a rebuild reverts to the declared default (or to unset if `defaultAgent = null`). This
  makes the default reproducible in the user's flake instead of runtime-only state, consistent with
  how theme/wallpaper/bar are treated. (If `defaultAgent = null`, activation leaves any existing
  runtime pick untouched — there is nothing declared to reconcile.)
- **D1:** rename `omarchy`→`omanix`, app-id `org.omarchy.agent`→`org.omanix.agent`, menu id
  `setup.default.agent`→`omanix` equivalent, `~/.config/omarchy/…`→`~/.config/omanix/…`.
- The fixed app-id launch in omarchy uses `omarchy-launch-tui --app-id=…`. Map onto omanix's
  existing `omanix-launch-tui` (see `pkgs/omanix-scripts/src/omanix-launch-tui`). Keep the
  `cd ~/Work` behavior only if omanix adopts a `~/Work` dir; otherwise drop it and note the omission.
- Add the picker to the menu: a checkable submenu whose entries call `omanix-default-agent <id>`,
  `checked` reflecting the current default. `omanix-agent --pick` summons it. If Q1-08's menu
  isn't ready, the picker may temporarily fall back to `omanix-menu-select`.
- Alias/keybind (optional, mirror upstream): `a='omanix-agent --inline'`; a Hyprland bind to
  `omanix-agent --pick`.

## Acceptance criteria
- [ ] `omanix-agent` and `omanix-default-agent` exist in `pkgs/omanix-scripts/src/` and are on PATH.
- [ ] `omanix-default-agent` with no args prints the current default (empty output when unset, exit 0).
- [ ] `omanix-default-agent <id>` writes `~/.config/omanix/defaults/agent` and launches the agent; no mise, no imperative install.
- [ ] `omanix.apps.ai.defaultAgent` (nullable, default `null`) is the declarative source of truth: when set it is reconciled onto `~/.config/omanix/defaults/agent` on every activation (declared wins; the file is a writable copy, never a store symlink), and a runtime `--pick` change is reverted on the next rebuild. An out-of-set value fails eval with a clear assertion.
- [ ] Supported agent ids are limited to those packaged by `llm-agents`; each has a correct auto-approve invocation.
- [ ] `omanix-agent` launches the default agent with app-id `org.omanix.agent`; `--inline` runs in-terminal; `--pick` opens the picker; `--prompt "x"` forwards the prompt.
- [ ] With no default set, `omanix-agent` (no `--pick`) prints guidance and exits non-zero; `--pick` opens the picker.
- [ ] Selecting an agent whose binary is absent surfaces the `omanix.apps.ai.*.enable` option to enable, rather than trying to install.
- [ ] No `omarchy`/`OMARCHY_PATH`/`org.omarchy.*` strings remain in the ported scripts.
- [ ] `nix flake check` passes.

## Testing
- `nix flake check`; `nix build .#omanix-scripts` (or the relevant attr) succeeds.
- With `omanix.apps.ai.claudeCode.enable = true`: `omanix-default-agent claude` writes the file and launches; `omanix-default-agent` echoes `claude`.
- `omanix-agent --inline` starts claude with `--permission-mode auto` in the current terminal.
- Unset the file: `omanix-agent` exits non-zero with guidance; `omanix-agent --pick` opens the picker.
- Grep the ported scripts for `omarchy`/`mise` → no matches.

## References
- omarchy: `bin/omarchy-agent`, `bin/omarchy-default-agent`, `bin/omarchy-agent-prompt`, `bin/omarchy-launch-tui`, menu entry `setup.default.agent` in `default/omarchy/omarchy-menu.jsonc`, `default/bash/aliases`, `default/hypr/bindings/utilities.lua`
- omanix: `pkgs/omanix-scripts/src/`, `pkgs/omanix-scripts/default.nix`, `modules/home-manager/apps/ai.nix`, `modules/home-manager/desktop/hyprland/bindings.nix`
