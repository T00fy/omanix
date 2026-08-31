# Q1-02: `pkgs/omanix-shell` — vendor shell/ QML tree + rename patch + assets

- **Phase:** 1
- **Status:** todo
- **Depends on:** Q0-03, Q1-01
- **Blocks:** Q1-03, Q2-01
- **Size:** L

## Context
The heart of the port: package omarchy's QML `shell/` tree into the Nix store as `omanix-shell`,
with the D1 rename applied, so it can be launched as `quickshell -n -p $OMANIX_PATH/shell`. The
upstream tree is ~175 files across `shell/{Commons,Ui,services,plugins}` plus `shell/shell.qml`,
and includes non-QML assets that plugins read relative to their dir (e.g. `emojis.json`, agent
`assets/*.svg`, per-plugin helper `.sh`/`.py` scripts). This ticket produces the store package;
runtime wiring is Q1-03.

## Scope
**In scope:** a derivation that takes pinned omarchy source (Q0-01), applies the rename helper
(Q0-03), and installs the `shell/` tree + all its assets into a predictable store layout.
**Out of scope:** exporting `OMANIX_PATH` / autostart / seeding config (Q1-03); making
individual plugins functional (Q1-05+); theming tomls (Q2-*).

## Implementation notes
- Create `pkgs/omanix-shell/default.nix`. Follow the packaging conventions in
  `pkgs/omanix-scripts/default.nix` (stdenv derivation, `installPhase`, `meta`).
- Inputs: `omarchySrc` (from `inputs.omarchy-src`, Q0-01) and the rename helper from Q0-03.
- Build steps:
  1. Take `${omarchySrc}/shell` as the source subtree.
  2. Apply the Q0-03 rename helper to it (deterministic `omarchy`→`omanix` sweep).
  3. Install to a stable path. Recommended: `$out/share/omanix/shell/...` so `OMANIX_PATH`
     = `$out/share/omanix` and the launch line is `quickshell -n -p $OMANIX_PATH/shell`
     (mirrors upstream `$OMARCHY_PATH/shell`). **Coordinate this exact path with Q0-02/Q1-03.**
- **Preserve the full tree verbatim** (minus the rename): `Commons/` (with `qmldir` singletons
  `Border/Color/Style/Util`), `Ui/`, `services/` (incl. `PluginRegistry.qml`,
  `BarWidgetRegistry.qml`, `AppLibrary.qml`, `hidden-entries.sh`), `plugins/**`, `shell.qml`.
- **Ship non-QML assets** — do not drop them: `emojis.json`, agent `assets/*.svg`, per-plugin
  helper scripts (`clipboard/capture.sh`, `image-picker/list.sh`, `dropbox/status.py`, etc.),
  `*.manifest.json` / adjacent `*.manifest.json` bar-widget manifests, `shell/plugins/README.md`.
  Enumerate via `git -C /home/toofy/projects/omarchy ls-tree -r --name-only v4.0.2:shell/`.
- **Do not text-rename binary/asset files** — the Q0-03 helper already restricts substitutions
  to text extensions; verify SVG/TTF/PNG pass through untouched.
- Nerd Font glyphs are embedded as raw multibyte chars in widget QML — ensure the build/copy
  path doesn't mangle encoding (plain `cp`, no `sed` that could strip codepoints; the rename
  helper's `sed` must be UTF-8 safe / scoped to ASCII patterns).
- Helper scripts inside the tree call sibling tools (`cliphist`, `wl-clipboard`, `jq`, `grim`,
  etc.). Those runtime deps are provided at the session level, not necessarily wrapped here —
  note which are expected on PATH; full wiring is per-plugin (Q1-05+). This ticket just ships
  the files intact.
- Add `omanix-shell` to the overlay in `flake.nix` and pass `omarchySrc = inputs.omarchy-src`.

## Acceptance criteria
- [ ] `nix build .#omanix-shell` succeeds.
- [ ] `$out/share/omanix/shell/shell.qml` exists and all subdirs (`Commons`, `Ui`, `services`, `plugins`) are present.
- [ ] Non-QML assets present: `emojis.json`, agent SVGs, per-plugin helper scripts, plugin manifests.
- [ ] Rename verified: no `omarchy-`/`OMARCHY_PATH` in text files; plugin ids are `omanix.*`; binaries untouched.
- [ ] Glyph encoding intact (spot-check a widget QML with embedded Nerd Font chars).
- [ ] `pkgs.omanix-shell` exposed via overlay; `nix flake check` passes.

## Testing
```bash
cd /home/toofy/projects/omanix
nix build .#omanix-shell
out=$(nix path-info .#omanix-shell)
test -f "$out/share/omanix/shell/shell.qml"
ls "$out/share/omanix/shell/plugins"                       # bar, menu, notifications, osd, ...
test -f "$out/share/omanix/shell/plugins/emojis"/*.json 2>/dev/null || \
  find "$out/share/omanix/shell" -name 'emojis.json'       # asset present somewhere
! grep -rIl 'OMARCHY_PATH' "$out/share/omanix/shell"
find "$out/share/omanix/shell" -name '*.svg' | head -1     # assets shipped
nix flake check
```
Runtime confirmation happens in Q1-03 (launching it). Optionally, `quickshell -n -p
"$out/share/omanix/shell"` in a Hyprland session should at least start without fatal QML errors
(some plugins may warn until wired).

## References
- omarchy: `shell/` tree (`git -C /home/toofy/projects/omarchy ls-tree -r --name-only v4.0.2:shell/`), `shell/README.md`, `docs/omarchy-shell.md`
- omanix: new `pkgs/omanix-shell/default.nix`; pattern from `pkgs/omanix-scripts/default.nix`; overlay in `flake.nix`; rename helper (Q0-03)
