# Omanix → Quattro parity: task tickets

This directory holds the work tickets that, when all completed, bring omanix to feature
parity with Omarchy 4.0.2 ("Quattro") for the agreed scope. The high-level plan and the
locked decisions live in [`../PORTING-QUATTRO.md`](../PORTING-QUATTRO.md) — **read it first.**

Each ticket is a self-contained markdown file designed to be picked up by an agent with
**minimal prior context**. A ticket must give enough background, file pointers, acceptance
criteria, and test steps that an agent can complete it by reading only: the ticket, this
README, `../PORTING-QUATTRO.md`, and the referenced source files.

## Repos an agent will touch

- **omanix** (this repo, `/home/toofy/projects/omanix`, branch `quattro`) — where work lands.
- **omarchy** (`/home/toofy/projects/omarchy`, tag/branch `v4.0.2` or `quattro`) — the upstream
  reference to port *from*. Read-only; use `git show v4.0.2:<path>` or check out files to study.

## Locked decisions (apply to every ticket)

- **D1 — Naming:** everything vendored from omarchy is renamed `omarchy` → `omanix`,
  `OMARCHY_PATH` → `OMANIX_PATH`, `omarchy.` → `omanix.` (plugin IPC ids). omanix takes a
  **committed in-repo snapshot** of upstream (Q0-01), and the rename is applied **once, at vendor
  time**, by a deterministic ruleset (Q0-03) whose renamed output is committed to `vendor/`. It is
  not a build-time patch and not a hand-diverged fork of a live input: `nix build` consumes the
  already-renamed committed tree. omanix owns the copy and does not track upstream; re-vendoring a
  newer omarchy is a rare, manual re-run of the vendor script + diff review.
- **D2 — Theming:** build `colors.toml` + `shell.toml` for **all** themes into the store
  (declarative, reproducible, build-checked). The declared `omanix.theme` is the source of
  truth and is applied on every rebuild/restart. Runtime IPC theme switching is an **ephemeral
  overlay** that reverts on activation.
- **D3 — AI agents:** provided declaratively via the existing `llm-agents` flake input. **No
  mise.** Port the agent abstraction, not the mise provisioning.
- **D4 — Runtime switching of declared config is out of scope by default.** Anything Nix declares
  (default browser/editor/terminal, timezone, DNS, …) is set in the flake, and the shell's
  runtime picker/panel/menu-entry for it is **disabled** — not ported. Keep a runtime switch only
  as a D2-style **ephemeral overlay** (declared value = source of truth, reverts on rebuild) where
  instant switching has genuine UX value (theme, monitor scaling, power profile). Q0-05 holds the
  authoritative per-command disposition.

## Out of scope (do not write tickets for)

Install/provisioning/channels/upgrade, the migration runner, factory reset/snapshots, and
pacman guard/ALPM hooks/etc-overrides — all obsoleted by Nix. Hyprland `.conf`→`.lua` is
already done in omanix.

## Ticket file naming

`<ID>-<kebab-slug>.md`, e.g. `Q1-02-vendor-shell-qml.md`. IDs are stable; never renumber.

## Workflow for an agent picking up a ticket

1. Read the ticket, this README, and `../PORTING-QUATTRO.md`.
2. Check **Depends on** — do not start until dependencies are ✅ in the status board below.
3. Do the work on the `quattro` branch.
4. Satisfy every acceptance criterion; run the tests in the Testing section.
5. Update this README's status board (set the ticket to ✅) and check the boxes in the ticket.
6. Commit atomically referencing the ticket ID (e.g. `Q1-02: vendor shell QML tree`).

## Ticket template (follow exactly)

```markdown
# <ID>: <Title>

- **Phase:** <0-5>
- **Status:** todo            <!-- todo | in-progress | done | blocked -->
- **Depends on:** <IDs or "none">
- **Blocks:** <IDs or "none">
- **Size:** <S | M | L>

## Context
Why this exists and what it delivers, written for an agent with no prior context. Name the
omarchy source and the omanix files involved.

## Scope
**In scope:** ...
**Out of scope:** ...

## Implementation notes
Concrete guidance: omanix files to create/edit, omarchy source paths to port from, the
relevant decision (D1/D2/D3), and known gotchas.

## Acceptance criteria
- [ ] Specific, verifiable outcomes.

## Testing
Exact commands / checks to prove it works (nix build/eval, runtime/visual checks, tests).

## References
- omarchy: <paths>
- omanix: <paths>
```

## Testing conventions (omanix)

- **Build/eval:** `nix flake check` and `nix build .#<attr>` are the baseline gate for any
  ticket touching nix. A ticket is not done if it breaks `nix flake check`.
- **Docs:** if a ticket adds/changes an `omanix.*` option, the generated options doc
  (`packages.x86_64-linux.docs`) must still build.
- **Runtime/visual:** shell/UI tickets require a runtime check in a Hyprland session (launch
  the component, confirm it renders/behaves). State the exact check in the ticket.
- **Scripts:** ported `omanix-*` scripts should be exercised with a documented invocation.

---

## Dependency graph (high level)

```
Q0-* (foundations) ─┐
                    ├─► Q1-01 (quickshell builds) ─► Q1-02 (vendor shell) ─► Q1-03 (session) ─► Q1-04 (IPC CLI)
                    │                                                                │
                    │                                        ┌───────────────────────┴───────────────┐
                    │                                        ▼                                        ▼
                    │                             Q1-05..Q1-14 (built-in plugins)          Q2-* (theming → shell)
                    │                                        │                                        │
                    │                                        └──────────────┬─────────────────────────┘
                    │                                                       ▼
                    │                                          Q3-* (retire old stack, rewire binds)
                    │
                    └─► Q4-* (plugin CLI + independent helpers — mostly parallel, few need Q1)
                                                       │
                                          Q5-* (AI agents — need Q1 shell + Q4-01 plugin CLI)
```

Phases 1→3 are a hard chain. Phase 4 items are largely independent (per-item deps noted in
each ticket). Phase 5 depends on the shell (Phase 1) and the plugin CLI (Q4-01).

---

## Status board

Update the Status column as tickets progress. Legend: ⬜ todo · 🟡 in-progress · ✅ done · ⛔ blocked.

### Phase 0 — Foundations
| ID | Title | Depends on | Status |
|----|-------|-----------|--------|
| Q0-01 | Vendor omarchy source snapshot into the repo | none | ⬜ |
| Q0-02 | Define `OMANIX_PATH` session-env mechanism | Q0-01 | ⬜ |
| Q0-03 | `omarchy`→`omanix` rename ruleset (applied at vendor time, D1) | Q0-01, Q0-05 | ⬜ |
| Q0-04 | Runtime state dir layout (`~/.local/state/omanix`) | none | ✅ |
| Q0-05 | Shell external-command contract & plugin scope | Q0-01 | ✅ |

### Phase 1 — Quickshell bring-up (keystone)
| ID | Title | Depends on | Status |
|----|-------|-----------|--------|
| Q1-01 | Validate/package Quickshell with required Qt service modules | Q0-01 | ✅ |
| Q1-02 | `pkgs/omanix-shell`: package vendored shell/ QML tree + assets | Q0-03, Q1-01 | ⬜ |
| Q1-03 | HM module: Quickshell session integration + seed `shell.json` | Q0-02, Q0-05, Q1-02 | ⬜ |
| Q1-04 | `omanix-shell` IPC CLI wrapper | Q1-03 | ✅ |
| Q1-05 | Bar plugin + core bar widgets | Q1-04 | ⬜ |
| Q1-06 | Notifications plugin | Q1-04 | ⬜ |
| Q1-07 | OSD plugin + `omanix-osd` | Q1-04 | ⬜ |
| Q1-08 | Menu/launcher plugin + app search | Q1-04 | ⬜ |
| Q1-09 | Clipboard + emoji plugins + CLIs | Q1-04 | ⬜ |
| Q1-10 | Background overlay plugin | Q1-04 | ⬜ |
| Q1-11 | Lock plugin (PAM) + Nix PAM wiring | Q1-04 | ⬜ |
| Q1-12 | Idle service plugin | Q1-04 | ⬜ |
| Q1-13 | polkit / media / network / bluetooth / tray / power plugins | Q1-04 | ⬜ |
| Q1-14 | `omanix-bar` + `omanix-restart/refresh-shell` + `omanix-shell-config` | Q1-04 | ⬜ |

### Phase 2 — Theming → shell (hybrid, D2)
| ID | Title | Depends on | Status |
|----|-------|-----------|--------|
| Q2-01 | Emit `colors.toml` per theme from existing palette | Q1-02 | ⬜ |
| Q2-02 | Port `shell.toml.tpl` (13 sections) → Nix generation | Q2-01 | ⬜ |
| Q2-03 | Build all themes' tomls; apply declared theme on activation via IPC | Q2-02, Q1-04 | ⬜ |
| Q2-04 | `omanix-theme-color` resolver + `omanix-theme-set` (ephemeral runtime switch) | Q2-03 | ⬜ |
| Q2-05 | `omanix-theme-switcher` + background helpers (bg-cache/switcher/current) | Q2-04, Q1-08 | ⬜ |
| Q2-06 | Theme security boundary (deny code from cloned themes) | Q2-04 | ⬜ |
| Q2-07 | Reconcile stale theme docs (README/CLAUDE) | none | ⬜ |

### Phase 3 — Retire old stack
| ID | Title | Depends on | Status |
|----|-------|-----------|--------|
| Q3-01 | Rewire Hyprland bindings to shell IPC | Q1-05..Q1-13 | ⬜ |
| Q3-02 | Rewire Hyprland autostart (drop old daemons) | Q1-03, Q1-06, Q1-07, Q1-10 | ⬜ |
| Q3-03 | Remove/gate waybar/walker/elephant/mako/swayosd/hyprlock/hypridle modules | Q3-01, Q3-02, Q2-03 | ⬜ |
| Q3-04 | Clipboard/menu helper CLIs (`omanix-menu-*`, `omanix-clipboard-*`) | Q1-09 | ⬜ |
| Q3-05 | Retire/repurpose `omanix-menu.sh`; fix dangling script refs | Q3-01 | ⬜ |

### Phase 4 — Plugin system + independent helpers (parallel)
| ID | Title | Depends on | Status |
|----|-------|-----------|--------|
| Q4-01 | Plugin CLI (`omanix-plugin-*`) + `omanix-menu-plugin` | Q1-04 | ✅ |
| Q4-02 | Hardware detection (`omanix-hw-*`) | none | ⬜ |
| Q4-03 | Audio tuning subsystem (PipeWire filter-chain) | none | ✅ |
| Q4-04 | Network tools (`omanix-network-*`) | none | ⬜ |
| Q4-05 | Capture tools (QR/region/OCR/webcam/image transcode) | none | ⬜ |
| Q4-06 | Security: sshd + sudoless-docker → Nix module options | none | ⬜ |
| Q4-07 | Tailscale taildrop send/receive | none | ⬜ |
| Q4-08 | Gaming: Battle.net + RetroArch retro | none | ⬜ |
| Q4-09 | Plymouth boot-splash theming (hybrid, mirrors D2) | Q2-01 | ⬜ |
| Q4-10 | Palette-only theme targets (tmux/claude/pi/browser/osc) | Q2-04 | ⬜ |
| Q4-11 | herdr: package + config + bindings + dev-layout fns | none | ⬜ |
| Q4-12 | Custom branding: About screen + logo→ANSI | none | ⬜ |

### Phase 5 — AI agents (optional; depends on shell)
| ID | Title | Depends on | Status |
|----|-------|-----------|--------|
| Q5-01 | `omanix-agent` launcher + `omanix-default-agent` picker | Q1-08, D3 | ⬜ |
| Q5-02 | Agents usage widget (Quickshell plugin + Python collectors) | Q1-05, Q4-01 | ⬜ |
| Q5-03 | Crash-watch service + `omanix-agent-crash` | Q5-01 | ⬜ |
| Q5-04 | Agent skills provisioning (symlink fan-out) | Q5-01 | ⬜ |
