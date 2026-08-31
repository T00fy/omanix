# Q1-03: HM module — Quickshell session integration + seed `shell.json`

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q0-02, Q0-05, Q1-02
- **Blocks:** Q1-04
- **Size:** M

## Context
With the shell packaged (Q1-02) and `OMANIX_PATH` defined (Q0-02), this ticket makes the shell
actually launch in a Hyprland session and gives it a user-writable `shell.json` to read. Upstream
launches the shell from Hyprland autostart as `quickshell -n -p $OMARCHY_PATH/shell` and reads
runtime config from `~/.config/omarchy/shell.json` (seeded from `config/omarchy/shell.json`). The
config is mutated at runtime over IPC (bar layout edits, enabled plugins), so it must be a
**writable copy, not a store symlink** (risk R3).

But `shell.json` also carries values you **declare in Nix** (bar layout/position, idle timeouts,
disabled plugins). A naive "seed only if missing" makes those declared values go stale: once the
file exists, changing the Nix option and rebuilding has no effect. So activation must **reconcile**
the declared subset on every rebuild — declared config is always the source of truth — while
leaving genuine runtime-only edits intact. This ticket defines that contract once (see
**Declarative reconcile contract** below); Q1-05, Q1-12, Q2-05, and Q5-01 reference it.

## Scope
**In scope:** a home-manager module that exports `OMANIX_PATH`, autostarts the shell, and seeds
`~/.config/omanix/shell.json`; a module option to enable it and set the package.
**Out of scope:** the IPC CLI (Q1-04); per-plugin behavior (Q1-05+); theming (Q2-*).

## Implementation notes
- Create `modules/home-manager/desktop/shell.nix` (import it from
  `modules/home-manager/default.nix` or the desktop aggregator — match how existing `desktop/`
  and `ui/` modules are wired). Follow existing module option style under `omanix.*`.
- Options: `omanix.shell.enable` (bool), `omanix.shell.package` (default `pkgs.omanix-shell`),
  optionally `omanix.shell.path` used by Q0-02 to compute `OMANIX_PATH`.
- **Env:** ensure `OMANIX_PATH` is exported (this is Q0-02's mechanism — coordinate the exact
  attribute; `OMANIX_PATH = "${cfg.package}/share/omanix"`). Add the Hyprland `env` entry (or
  reference Q0-02's).
- **Autostart:** add to `modules/home-manager/desktop/hyprland/autostart.nix` (which uses
  `hl.on("hyprland.start", ...)` + `hl.exec_cmd(...)`). Launch:
  `quickshell -n -p $OMANIX_PATH/shell`. Coexist with the old stack during transition — do NOT
  remove mako/swayosd/swaybg autostarts here; that's Q3-02. (During bring-up you may run both;
  expect visual overlap.)
- **Seed + reconcile `shell.json`:** this replaces a naive seed-if-missing — see the
  **Declarative reconcile contract** below. In short: Nix renders a **declarative base**
  `shell.json` into the store from the enabled `omanix.*` options (the vendored upstream default,
  `config/omarchy/shell.json`, is the starting point for defaults not driven by an option); a
  `home.activation` step **deep-merges that base over** the user's existing
  `~/.config/omanix/shell.json` so declared keys always win, then best-effort reloads the running
  shell. Never symlink into the store (R3) — the on-disk file stays a writable copy. In this
  ticket the declared base may be nearly the raw default; later tickets add option-driven keys to
  it.
- The `-n` flag runs quickshell without its own config dir daemonization conflicts — keep parity
  with upstream's invocation.
- Confirm required runtime tools the shell shells out to are on the session PATH (jq, wl-clipboard,
  cliphist, etc.) — add to the module's `home.packages` or the shell package's wrapping as needed
  for a minimal boot (full per-plugin deps come in Q1-05+).

### Declarative reconcile contract (D2 — declared config always wins)

`shell.json` holds two logical layers that must not be conflated:

1. **Declared layer** — every key sourced from an `omanix.*` option (e.g. `bar.layout`,
   `bar.position`, `bar.transparent`, `disabledPlugins`, the `idle` block). These keys are added
   incrementally by later tickets (bar layout → Q1-05; idle block → Q1-12; etc.). The Nix
   declaration is the **permanent source of truth** for them.
2. **Runtime layer** — keys the shell writes over IPC that have *no* declared counterpart
   (ad-hoc, user-only state). These survive across rebuilds.

Mechanism (define it here; later tickets only add keys to the declared base):

- Nix renders a **declarative base** `shell.json` into the store from the enabled `omanix.*`
  options. This is the reproducible, build-checked artifact. The base must also carry the
  `disabledPlugins` set and any removed menu entries defined by **Q0-05** (the out-of-scope cuts:
  DNS panel, default browser/editor/terminal pickers, timezone picker, SystemUpdate widget, and
  any features decided "disable"), so the shell never invokes a command that has no omanix
  implementer.
- A `home.activation` step reconciles it into `~/.config/omanix/shell.json` by a **deep merge
  where the declared base wins** — e.g. `jq -s '.[0] * .[1]'` with the user file as `.[0]` and the
  declared base as `.[1]` (objects merge recursively; declared arrays like `bar.layout` replace
  wholesale). Consequences:
  - declared keys are **re-applied on every rebuild/activation** — a runtime IPC change to a
    declared key is reverted on the next rebuild (the intended D2 ephemerality);
  - runtime-only keys with no declared counterpart are preserved;
  - the step is **idempotent** and **never a store symlink** (R3) — the file stays writable.
- After writing, **best-effort** nudge the running shell to reload (`omanix-shell` IPC, or
  `omanix-refresh-shell` from Q1-14). Activation **must succeed whether or not the shell is
  running** and must not fail if the reload errors; the authoritative path is the on-disk file the
  shell reads on next launch.
- On a *fresh* machine (no user file) the merge degenerates to "write the declared base," so
  first boot still works.

This is the same declared-source-of-truth + ephemeral-runtime-overlay split D2 defines for themes
(Q2-03/Q2-04), applied to the shell-config axis.

## Acceptance criteria
- [ ] `omanix.shell.enable = true` launches the Quickshell process on Hyprland start.
- [ ] `OMANIX_PATH` is set in the session and resolves to the shell package (`$OMANIX_PATH/shell/shell.qml` exists).
- [ ] `~/.config/omanix/shell.json` is a writable copy (never a store symlink); on a fresh machine it is created from the declared base.
- [ ] On rebuild, keys owned by `omanix.*` options are reconciled to their declared values (declared config wins), while runtime-only keys with no declared counterpart are preserved. The activation step is idempotent and succeeds whether or not the shell is running.
- [ ] The old stack still runs alongside (no premature removal); no fatal startup crash.
- [ ] `nix flake check` passes; options doc builds.

## Testing
```bash
cd /home/toofy/projects/omanix
nix flake check
nix build .#packages.x86_64-linux.docs
```
Runtime (Hyprland session with `omanix.shell.enable = true`):
- `pgrep -af quickshell` shows the process running against `$OMANIX_PATH/shell`.
- `echo $OMANIX_PATH` prints the store path; `cat ~/.config/omanix/shell.json` exists and is writable.
- The bar (or at least the shell root) appears without QML fatal errors in `journalctl --user` / stderr.
- Change a **declared** value (once options exist, e.g. bar position via its `omanix.*` option), rebuild → the on-disk `shell.json` reflects the declared value (declared wins), even after a prior runtime IPC change to that key.
- Hand-add a **runtime-only** key that no `omanix.*` option manages, rebuild → that key is preserved.
- Run activation with the shell not running → it succeeds (the best-effort reload does not fail activation).

## References
- omarchy: launch in Hyprland autostart (`default/hypr/apps/omarchy-shell.lua`), `config/omarchy/shell.json`, `docs/omarchy-shell.md`
- omanix: new `modules/home-manager/desktop/shell.nix`; `modules/home-manager/desktop/hyprland/autostart.nix`; `envs.nix` (Q0-02)
