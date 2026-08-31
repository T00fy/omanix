# Q5-04: Agent skills provisioning (symlink fan-out)

- **Phase:** 5
- **Status:** todo
- **Depends on:** Q5-01 (agent abstraction)
- **Blocks:** none
- **Size:** S

## Context
Omarchy 4.0.2 ships "skills" — agent instruction packs under `default/agents/skills/`. Two
ship to end users: `omarchy/` (a large customization skill covering Hyprland, theming, hooks,
plugins, capture, contributing) and `diagnose-crash/` (the method behind `omarchy-agent-crash`,
see Q5-03). `omarchy-provision-user` fans each skill dir out as symlinks into every supported
agent's skills dir: `~/.agents/skills/`, `~/.claude/skills/`, `~/.codex/skills/`,
`~/.pi/agent/skills/`, `~/.gemini/config/skills/`.

Omanix has no skills provisioning today.

## Scope
**In scope:** Ship omanix's skill packs and place them into the skills dirs of the agents the
user has enabled, declaratively via home-manager. Rebrand the `omarchy` skill to `omanix`.
**Out of scope:** the imperative `omarchy-provision-user` runner (out of scope per PORTING plan);
this is a pure home-manager file/symlink concern.

## Implementation notes
- **D1:** rebrand the shipped `omarchy` skill to `omanix` (its content references omarchy
  commands/paths — update to `omanix-*`, `~/.config/omanix`, etc.). The `diagnose-crash` skill
  is mostly generic; keep it, adjust any `omarchy-*` references.
- **Declarative, not imperative:** don't port the `provision-user` symlink loop. Instead use
  home-manager `home.file` / `xdg.configFile` to place the skills. Options:
  - Ship skill sources in-repo under e.g. `assets/agent-skills/{omanix,diagnose-crash}/`.
  - For each **enabled** agent (gate on `omanix.apps.ai.*.enable`), create the agent's skills
    dir entries pointing at the shipped skills. home-manager symlinks into the store are fine
    here (skills are read-only content), unlike mutable config.
- **Scope to installed agents:** only populate skills dirs for agents actually enabled. Claude
  → `~/.claude/skills/`; opencode → its skills location; add others only as omanix packages them.
  Do not create dirs for agents that aren't installed.
- Keep the mapping in one place so adding an agent (Q5-01) is a one-line addition here.
- `diagnose-crash` must land wherever `omanix-agent-crash` (Q5-03) points the agent.

## Acceptance criteria
- [ ] Skill sources for `omanix` and `diagnose-crash` exist in-repo, rebranded (no stray `omarchy` refs).
- [ ] Enabling `omanix.apps.ai.claudeCode.enable` places both skills under `~/.claude/skills/`.
- [ ] Skills are placed only for enabled agents; disabled agents get no skills dirs.
- [ ] Adding a new supported agent requires only a single mapping entry here.
- [ ] `nix flake check` passes; the generated options doc still builds if a new option is added.

## Testing
- `nix flake check`.
- In a test HM config with `claudeCode.enable = true`, activate and confirm
  `~/.claude/skills/omanix/` and `~/.claude/skills/diagnose-crash/` resolve to the shipped content.
- With all AI agents disabled, confirm no skills dirs are created.
- Grep shipped skill content for `omarchy` → no matches.

## References
- omarchy: `default/agents/skills/{omarchy,diagnose-crash}/`, skill fan-out in `bin/omarchy-provision-user`
- omanix: `assets/` (add `agent-skills/`), `modules/home-manager/apps/ai.nix`
