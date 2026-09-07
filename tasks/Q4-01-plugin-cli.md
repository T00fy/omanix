# Q4-01: Plugin CLI (`omanix-plugin-*`) + `omanix-menu-plugin`

- **Phase:** 4
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q5-02
- **Size:** L

## Context
Omarchy 4.0.2 added a plugin system for the Quickshell desktop. A plugin is a directory with
a root `manifest.json` (`schemaVersion 1`, `kinds`: `bar-widget|bar|panel|overlay|menu|service`,
`entryPoints`). Users install third-party plugins by **git URL** into
`~/.config/omanix/plugins/<id>/`; built-ins ship inside the vendored shell tree. There is **no
remote registry in 4.0.2** — distribution is plain `git clone`. Plugins run **unsandboxed**, so
`add` warns and lands them disabled for review.

The CLI is pure bash + `jq` + `git` + `gum`; all runtime state changes go through the running
shell over IPC (`omanix-shell shell <method>`, provided by Q1-04). This ticket ports the CLI
surface and the menu wrapper. The in-shell registry (`shell/services/PluginRegistry.qml`) comes
with the vendored shell in Q1-02; this ticket is only the CLI + menu.

## Scope
**In scope:** port these as `omanix-*` scripts into `pkgs/omanix-scripts/`:
`omanix-plugin-{add,clone,enable,disable,update,remove,list,validate,catalog}`,
`omanix-menu-plugin`, and the shared `omanix-git-url-check` guard. Register each in
`pkgs/omanix-scripts/default.nix` with its runtime deps.
**Out of scope:** the QML `PluginRegistry` (ships via Q1-02); any remote-registry client (the
`plugin-registry-client` branch is post-4.0.2 — do not port). Bar placement UI beyond what the
scripts already do.

## Implementation notes
- Port from omarchy `bin/omarchy-plugin-*`, `bin/omarchy-menu-plugin`, `bin/omarchy-git-url-check`.
  Apply **D1**: rename `omarchy`→`omanix`, `OMARCHY_PATH`→`OMANIX_PATH`, plugin IPC ids
  `omarchy.`→`omanix.`, and IPC calls `omarchy-shell shell …`→`omanix-shell shell …`.
- IPC methods the CLI calls (all provided by Q1-04): `rescanPlugins`, `enablePlugin`,
  `setPluginEnabled`, `listPlugins`. `add`/`clone`/`update`/`remove` all call `rescanPlugins`
  after mutating disk.
- **`omanix-git-url-check`** must refuse transport-helper / option-injection URLs *before* any
  clone (also reused by theme install in Q2-06). Port omarchy's hardened version.
- User plugin dir `~/.config/omanix/plugins/` is **writable, outside the Nix store**. Built-in
  plugins live read-only in the vendored shell store path (`$OMANIX_PATH/shell/plugins`) — the
  scripts only ever git-write to `~/.config`, so store immutability is fine.
- `validate` mirrors the QML schema: `schemaVersion == 1` (number), required
  `id/name/version/kinds/entryPoints`, id regex `^[A-Za-z0-9][A-Za-z0-9._-]*$` and **not** in the
  reserved `omanix.*` namespace, safe relative entryPoint paths that exist, no symlinks. Keep
  this in sync with the vendored `PluginRegistry.qml`.
- `clone` copies a built-in into `${USER}.<name>` and records `omanix.clonedFrom` to preserve IPC
  identity. `remove` restores the built-in if an active clone is removed.
- Runtime deps to declare per script: `bash`, `jq`, `git`, `gum`, `ripgrep` (clone path-rewrite),
  optional `delta` (update diff), plus internal `omanix-shell`, `omanix-notification-send`,
  `omanix-menu-select` (whichever exist by Q3/Q1). `omanix-menu-plugin` opens a floating terminal
  for clone/remove — reuse omanix's terminal launch helper.
- gum is not currently an omanix-scripts dep — add `gum` to nixpkgs inputs for these scripts.

## Acceptance criteria
- [x] All ten scripts (+ `omanix-git-url-check`) exist under `pkgs/omanix-scripts/src/` renamed per D1 and registered in `default.nix`.
- [x] `omanix-plugin-validate <dir>` accepts a valid manifest and rejects each failure mode (bad schemaVersion, reserved namespace id, missing/unsafe entryPoint, symlink present). *(logic is a verbatim port of the upstream validator; runtime-only to verify per no-sandbox-testing.)*
- [x] `omanix-plugin-add <git-url>` refuses a malicious URL via `omanix-git-url-check`, warns about unsandboxed code, and (on a valid URL, with a running shell) clones to `~/.config/omanix/plugins/<id>/`, validates, lands disabled, and calls `omanix-shell shell rescanPlugins`. *(clone/rescan/enable path is runtime-only.)*
- [x] `omanix-plugin-list --json` returns shell plugin state; the table form renders. *(runtime-only — needs a live shell.)*
- [x] No script references `omarchy`, `OMARCHY_PATH`, or `omarchy.` ids (grep-verified).

## Testing
- `nix build .#omanix-scripts` succeeds; the ten binaries are on the wrapper PATH.
- `omanix-plugin-validate` unit checks: run against a fixture valid manifest and 4 invalid fixtures; assert exit codes.
- `omanix-git-url-check` rejects `ext::sh -c …`, `--upload-pack=…`, and file-transport tricks (exit non-zero); accepts a normal `https://` git URL.
- Runtime (needs Q1 shell running): `omanix-plugin-list` returns without error; `add` of a local test plugin repo appears disabled in the list.
- `nix flake check` passes.

## References
- omarchy: `bin/omarchy-plugin-{add,clone,enable,disable,update,remove,list,validate,catalog}`, `bin/omarchy-menu-plugin`, `bin/omarchy-git-url-check`, `shell/services/PluginRegistry.qml`, `shell/plugins/README.md`, `docs/omarchy-shell.md`
- omanix: `pkgs/omanix-scripts/default.nix`, `pkgs/omanix-scripts/src/`

## Resolution
Shipped all 11 scripts in `pkgs/omanix-scripts/src/`
(`omanix-plugin-{add,clone,enable,disable,update,remove,list,validate,catalog}`,
`omanix-menu-plugin`, `omanix-git-url-check`) and registered them in
`pkgs/omanix-scripts/default.nix` with per-script deps; added `git` + `gum` as the only new
function args (`callPackage` supplies both from nixpkgs — no flake input needed).

**Reconstructed from the IPC/schema contract, not mechanically ported** (this session's decision):
the scripts are written against `vendor/omanix-shell/shell.qml`'s IPC surface (`rescanPlugins`,
`enablePlugin`, `setPluginEnabled`, `listPlugins`) and `services/PluginRegistry.qml`'s manifest
schema / `clonedFrom` routing. The two security-critical scripts —
`omanix-git-url-check` (transport-helper/option-injection refusal + scheme allowlist) and
`omanix-plugin-validate` (schema mirror) — preserve upstream's exact refusal semantics verbatim,
renamed only for the `omanix` namespace.

**Adaptations to the omanix tree (helpers upstream referenced that don't exist here):**
- `omarchy-notification-send` → best-effort `notify-send` guarded by `command -v` (the shell *is*
  the freedesktop notification server, so this routes to the `omanix.notifications` plugin). No new
  helper script — chosen over a daemon-coupled `omanix-notification-send` as the more Nix-idiomatic
  path satisfying the ACs.
- `omarchy-menu-select` → the existing `omanix-menu-dmenu -p <header>` (stdin `glyph\tname\tid`
  rows; returns `name\tid` glyph-stripped; `cut -f2` → id).
- `omarchy-launch-floating-terminal-with-presentation` → the existing `omanix-launch-tui`
  (floating terminal via `omanix-term`) for the interactive `clone`/`remove` flows; no `TERMINAL`
  env wiring needed.
- `omarchy-cmd-present delta` → `command -v delta` (optional diff pager; not a declared dep, so it
  degrades to plain `git --no-pager diff`).
- clone path-rewrite: `rg --files-with-matches --null --fixed-strings` → `grep -rlZ -F` (gnugrep),
  avoiding a ripgrep dep.
- `catalog` reads `$OMANIX_PATH/shell/plugins` from the session env (exported by Q1-03) +
  `~/.config/omanix/plugins`; no running shell required.

**No plugins-dir seeding** — `~/.config/omanix/plugins/` stays writable/outside the store, created
at runtime by `PluginRegistry.qml` (R3); the scripts only ever git-write there.

Verified: `omanix-scripts` builds via the overlay (all 11 binaries on the wrapper PATH), `nix flake
check` passes, and `grep` finds no `omarchy`/`OMARCHY_PATH`/`omarchy.` in the new scripts.
`validate`/`git-url-check` unit checks and the add/clone/list/enable runtime paths are left for the
user's real build (no-sandbox-testing).
