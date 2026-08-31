# Q1-04: `omanix-shell` IPC CLI wrapper

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q1-03
- **Blocks:** Q1-05, Q1-06, Q1-07, Q1-08, Q1-09, Q1-10, Q1-11, Q1-12, Q1-13, Q1-14, Q2-03, Q4-01
- **Size:** S

## Context
Every shell interaction — toggling the launcher, showing the OSD, applying a theme, listing or
enabling plugins, moving bar widgets — goes through a single CLI that forwards IPC calls to the
running Quickshell process (`quickshell ipc`). Upstream this is `bin/omarchy-shell`. Almost all
of Phase 1's plugin tickets, theming (Q2-03 `applyTheme`), and the plugin CLI (Q4-01) depend on
this wrapper existing and being on PATH. Per D1 it's renamed `omanix-shell`.

## Scope
**In scope:** port `bin/omarchy-shell` → `omanix-shell`, packaged like the other `omanix-*`
scripts, on the session PATH.
**Out of scope:** the individual plugins that register IPC targets (their own tickets);
`omanix-bar`/`omanix-restart-shell`/etc. (Q1-14).

## Implementation notes
- Source: `bin/omarchy-shell` (already read; it validates `OMARCHY_PATH`, requires
  `<target> <method> [args...]`, supports `-q` quiet best-effort mode, and forwards to
  `quickshell ipc`). Apply D1 rename (`OMANIX_PATH`, `omanix-shell`, `omanix.*` in examples).
- Package it: add to `pkgs/omanix-scripts/default.nix` `scripts` list (name `omanix-shell`,
  deps at least `bash`, `coreutils`, and `quickshell` for the `quickshell ipc` binary; put the
  actual source at `pkgs/omanix-scripts/src/omanix-shell.sh`). Match the existing entry style.
  Alternatively, if it belongs with the shell package, place it wherever the team keeps shell
  CLIs — but the established pattern is `omanix-scripts`.
- It must find `quickshell` — inject via wrapper PATH (`--prefix PATH`) using `pkgs.quickshell`.
- **IPC surface it forwards** (targets/methods the shell exposes — the wrapper is generic, but
  document these so dependent tickets know the contract):
  - `shell` target: `ping`, `summon`/`hide`/`toggle <id> [payloadJson]`, `togglePanelAt`,
    `call`, `rescanPlugins`, `reloadConfig`, `applyTheme <colorsB64> <shellB64>`,
    `toggleBarTransparency`, `setPluginEnabled <id> <bool>`, `enablePlugin <id> <placementJson>`,
    `putBarWidget`/`moveBarWidget`/`setBarWidget`, `listPlugins`, `listShellConfig`,
    `debugBarGeometry`.
  - Per-plugin targets register their own names (e.g. `omanix.menu`, `omanix.clock`,
    `background`, `osd`, `media`, `notifications`, `omanix.power`). There is **no** `bar` target.
- Keep the `-q` quiet mode (used by best-effort refresh calls that must not fail if the shell
  isn't up).

## Acceptance criteria
- [ ] `omanix-shell` is packaged and on the session PATH.
- [ ] `omanix-shell shell ping` against a running shell returns success/pong.
- [ ] Fails with a clear message when `OMANIX_PATH` is unset (parity with upstream) and returns success under `-q` when the shell is down.
- [ ] Usage/help text and examples are renamed to `omanix`.
- [ ] `nix flake check` passes; the package builds.

## Testing
```bash
cd /home/toofy/projects/omanix
nix build .#omanix-scripts
nix flake check
```
Runtime (shell running from Q1-03):
```bash
omanix-shell shell ping           # -> pong / success
omanix-shell shell listPlugins    # -> JSON/plugin listing
omanix-shell -q omanix.nonexistent refresh   # -> exit 0, no output (quiet best-effort)
unset OMANIX_PATH; omanix-shell shell ping    # -> clear error, nonzero (non-quiet)
```

## References
- omarchy: `bin/omarchy-shell` (read in full during planning); `docs/omarchy-shell.md` (IPC contract)
- omanix: `pkgs/omanix-scripts/default.nix` + new `pkgs/omanix-scripts/src/omanix-shell.sh`
