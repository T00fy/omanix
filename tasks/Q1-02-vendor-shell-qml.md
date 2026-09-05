# Q1-02: `pkgs/omanix-shell` — package the vendored shell/ QML tree + assets

- **Phase:** 1
- **Status:** done
- **Depends on:** Q0-03, Q1-01
- **Blocks:** Q1-03, Q2-01
- **Size:** L

## Context
The heart of the port: package the vendored, already-renamed QML shell tree into the Nix store as
`omanix-shell`, so it can be launched as `quickshell -n -p $OMANIX_PATH/shell`. The source is the
**committed in-repo snapshot** at `vendor/omanix-shell/` (Q0-01), with the D1 rename already applied
at vendor time (Q0-03) — there is **no fetch and no build-time patch**. The tree is ~175 files
across `shell/{Commons,Ui,services,plugins}` plus `shell/shell.qml`, and includes non-QML assets
that plugins read relative to their dir (e.g. `emojis.json`, agent `assets/*.svg`, per-plugin helper
`.sh`/`.py` scripts). This ticket produces the store package; runtime wiring is Q1-03.

## Scope
**In scope:** a derivation that installs the committed `vendor/omanix-shell/` tree + all its assets
into a predictable store layout.
**Out of scope:** the vendoring/rename themselves (Q0-01/Q0-03 — done once, off the build path);
exporting `OMANIX_PATH` / autostart / seeding config (Q1-03); making individual plugins functional
(Q1-05+); theming tomls (Q2-*).

## Implementation notes
- Create `pkgs/omanix-shell/default.nix`. Follow the packaging conventions in
  `pkgs/omanix-scripts/default.nix` (stdenv derivation, `installPhase`, `meta`).
- **Source is in-repo, not an input.** The derivation's `src` is the committed `vendor/omanix-shell/`
  tree (e.g. `src = ../../vendor/omanix-shell;` or a `lib.cleanSource` of it). There is **no
  `omarchySrc` flake input** and **no rename step in the derivation** — the tree is already renamed
  and committed (Q0-01/Q0-03). Do not add `substituteInPlace`/`runCommand` rename logic here.
- Build steps:
  1. Take the committed `vendor/omanix-shell/` tree (already renamed).
  2. Install to a stable path. Recommended: `$out/share/omanix/shell/...` so `OMANIX_PATH`
     = `$out/share/omanix` and the launch line is `quickshell -n -p $OMANIX_PATH/shell`
     (mirrors upstream `$OMARCHY_PATH/shell`). **Coordinate this exact path with Q0-02/Q1-03.**
  - Confirm the vendored tree's top layout so the copy lands `shell.qml` at `$out/share/omanix/shell/shell.qml`
    (if `vendor/omanix-shell/` already *is* the `shell/` dir, copy it to `$out/share/omanix/shell`).
- **Install the full tree verbatim** (a plain `cp -r`, no text mutation): `Commons/` (with `qmldir`
  singletons `Border/Color/Style/Util`), `Ui/`, `services/` (incl. `PluginRegistry.qml`,
  `BarWidgetRegistry.qml`, `AppLibrary.qml`, `hidden-entries.sh`), `plugins/**`, `shell.qml`.
- **Ship non-QML assets** — do not drop them: `emojis.json`, agent `assets/*.svg`, per-plugin
  helper scripts (`clipboard/capture.sh`, `image-picker/list.sh`, `dropbox/status.py`, etc.),
  `*.manifest.json` bar-widget manifests, `shell/plugins/README.md`. They are already in the
  committed tree; just install them.
- Nerd Font glyphs are embedded as raw multibyte chars in widget QML — the copy must not mangle
  encoding (plain `cp`, no `sed`). (The rename already ran at vendor time with UTF-8-safe rules.)
- Helper scripts inside the tree call sibling tools (`cliphist`, `wl-clipboard`, `jq`, `grim`,
  etc.). Those runtime deps are provided at the session level, not necessarily wrapped here —
  note which are expected on PATH; full wiring is per-plugin (Q1-05+). This ticket just ships
  the files intact.
- Add `omanix-shell` to the overlay in `flake.nix`. No `omarchySrc` argument to thread.

## Acceptance criteria
- [x] `nix build .#omanix-shell` succeeds with no network fetch of upstream source (the tree is in-repo).
- [x] `$out/share/omanix/shell/shell.qml` exists and all subdirs (`Commons`, `Ui`, `services`, `plugins`) are present.
- [x] Non-QML assets present: `emojis.json`, agent SVGs, per-plugin helper scripts, plugin manifests.
- [x] Rename already in effect (from the committed tree): no `omarchy-`/`OMARCHY_PATH` in text files; plugin ids are `omanix.*`; binaries untouched. (The derivation does no renaming.)
- [x] Glyph encoding intact (175/175 files copied verbatim via plain `cp`, no `sed`).
- [x] `pkgs.omanix-shell` exposed via overlay; `nix flake check` passes; no `omarchy-src` input in `flake.nix`.

## Testing
```bash
cd /home/toofy/projects/omanix
nix build .#omanix-shell
out=$(nix path-info .#omanix-shell)
test -f "$out/share/omanix/shell/shell.qml"
ls "$out/share/omanix/shell/plugins"                       # bar, menu, notifications, osd, ...
find "$out/share/omanix/shell" -name 'emojis.json'         # asset present
! grep -rIl 'OMARCHY_PATH' "$out/share/omanix/shell"       # rename already applied upstream of build
find "$out/share/omanix/shell" -name '*.svg' | head -1     # assets shipped
nix flake check
```
Runtime confirmation happens in Q1-03 (launching it). Optionally, `quickshell -n -p
"$out/share/omanix/shell"` in a Hyprland session should at least start without fatal QML errors
(some plugins may warn until wired).

## References
- omarchy (reference only): `shell/` tree, `shell/README.md`, `docs/omarchy-shell.md`
- omanix: committed source `vendor/omanix-shell/` (Q0-01/Q0-03); new `pkgs/omanix-shell/default.nix`; pattern from `pkgs/omanix-scripts/default.nix`; overlay in `flake.nix`
