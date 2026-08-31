# Q4-01: Plugin CLI (`omanix-plugin-*`) + `omanix-menu-plugin`

- **Phase:** 4
- **Status:** todo
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
- [ ] All ten scripts exist under `pkgs/omanix-scripts/src/` renamed per D1 and registered in `default.nix`.
- [ ] `omanix-plugin-validate <dir>` accepts a valid manifest and rejects each failure mode (bad schemaVersion, reserved namespace id, missing/unsafe entryPoint, symlink present).
- [ ] `omanix-plugin-add <git-url>` refuses a malicious URL via `omanix-git-url-check`, warns about unsandboxed code, and (on a valid URL, with a running shell) clones to `~/.config/omanix/plugins/<id>/`, validates, lands disabled, and calls `omanix-shell shell rescanPlugins`.
- [ ] `omanix-plugin-list --json` returns shell plugin state; the table form renders.
- [ ] No script references `omarchy`, `OMARCHY_PATH`, or `omarchy.` ids.

## Testing
- `nix build .#omanix-scripts` succeeds; the ten binaries are on the wrapper PATH.
- `omanix-plugin-validate` unit checks: run against a fixture valid manifest and 4 invalid fixtures; assert exit codes.
- `omanix-git-url-check` rejects `ext::sh -c …`, `--upload-pack=…`, and file-transport tricks (exit non-zero); accepts a normal `https://` git URL.
- Runtime (needs Q1 shell running): `omanix-plugin-list` returns without error; `add` of a local test plugin repo appears disabled in the list.
- `nix flake check` passes.

## References
- omarchy: `bin/omarchy-plugin-{add,clone,enable,disable,update,remove,list,validate,catalog}`, `bin/omarchy-menu-plugin`, `bin/omarchy-git-url-check`, `shell/services/PluginRegistry.qml`, `shell/plugins/README.md`, `docs/omarchy-shell.md`
- omanix: `pkgs/omanix-scripts/default.nix`, `pkgs/omanix-scripts/src/`
