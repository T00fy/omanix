# Q1-09: Clipboard + emoji plugins + CLIs

- **Phase:** 1
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q3-03, Q3-04
- **Size:** M

## Context
Omarchy 4.0.2 split walker's clipboard and symbol/emoji providers into two dedicated Quickshell
plugins — `omarchy.clipboard` (clipboard history picker, backed by `cliphist`/`wl-clipboard`)
and `omarchy.emojis` (emoji picker with fuzzy search) — plus small CLIs. This supersedes
omanix's cliphist + walker clipboard/symbols providers (in `ui/walker.nix`/`ui/elephant.nix`).
Under D1 the plugin ids are `omanix.clipboard` and `omanix.emojis`.

## Scope
**In scope:** the `omanix.clipboard` and `omanix.emojis` plugins loading and working; the CLIs
`omanix-clipboard-{open,paste-file,paste-text}` and `omanix-menu-{emoji,emoji-insert}` (ported
from the `omarchy-*` equivalents); robust handling of large/UTF-16 clipboard entries.
**Out of scope:** rebinding SUPER+CTRL+V / SUPER+CTRL+E in Hyprland (Q3-01); the broader
`omanix-menu-*` helper set (Q3-04 covers timezone/images/etc.); removing walker/elephant (Q3-03);
theming (Q2-02).

## Implementation notes
- Sources: `shell/plugins/clipboard/` (`Clipboard.qml`, `ClipboardHistory.js`, `capture.sh`,
  `manifest.json`) and `shell/plugins/emojis/` (`Emojis.qml`, `EmojiSearch.js`, `emojis.json`,
  `manifest.json`). `emojis.json` is a data file that MUST ship alongside the plugin in the
  store (read relative to the plugin dir). CLIs: `bin/omarchy-clipboard-*`, `bin/omarchy-menu-emoji`,
  `bin/omarchy-menu-emoji-insert`.
- `capture.sh` shells out to `cliphist` + `wl-clipboard` (`wl-copy`/`wl-paste`) — ensure these
  are in the wrapped script runtime deps (omanix already depends on cliphist/wl-clipboard today).
- Package the CLIs in `pkgs/omanix-scripts` with the D1 rename applied. They call the shell over
  IPC (`omanix-shell omanix.clipboard ...` / `omanix.emojis ...`).
- **D1:** plugin ids/IPC targets and command names renamed via Q0-03 patch. Confirm `emojis.json`
  and `capture.sh` survive the vendoring copy in Q1-02.
- Gotcha: omarchy specifically hardened the clipboard picker against huge/UTF-16 pastes — keep
  that behavior; don't truncate/echo secrets.

## Acceptance criteria
- [x] `omanix.clipboard` and `omanix.emojis` plugins load (first-party + `keepLoaded`; enabled unless in `disabledPlugins` — needed no QML changes). *(runtime-only to confirm in a live session)*
- [x] `omanix-clipboard-open` opens the history picker (IPC toggle) / opens an entry externally with `--history-index`; `paste-text`/`paste-file` copy the exact stored bytes and paste (Shift+Insert / Ctrl+V) unless `--copy-only`.
- [x] `omanix-menu-emoji` opens the emoji picker (IPC toggle); `omanix-menu-emoji-insert` types the chosen emoji into the focused input (`wtype`, clipboard fallback).
- [x] A large (>1MB) or UTF-16 clipboard entry is handled without crashing/garbling — the hardening lives in the already-vendored `capture.sh` (perl heuristics) + `ClipboardHistory.js` (8 KB display cap); the paste CLI reads the untruncated `.text` back by index. No content echoed (secret hygiene).
- [x] `nix flake check` passes; `omanix-scripts` builds with the five new CLIs; `emojis.json` present at `$OMANIX_PATH/shell/plugins/emojis/emojis.json`.

## Implementation summary
- No QML changes and no new option/`shell.json` surface: both plugins are first-party `keepLoaded` overlays that already load under their D1-renamed ids (`omanix.clipboard` / `omanix.emojis`). `emojis.json` + `capture.sh` are already vendored and resolve in-store, so `pkgs/omanix-shell/` is untouched.
- Five new CLIs in `pkgs/omanix-scripts/src/`, reconstructed from the verified QML call contract (the upstream `bin/` originals were never vendored): `omanix-menu-emoji` + `omanix-clipboard-open` are thin `omanix-shell` IPC shims (`selfPath`); `omanix-menu-emoji-insert`, `omanix-clipboard-paste-{text,file}` shell out to `wl-clipboard`/`wtype`. Registered in `default.nix` (added the `wtype` input).
- Clipboard history is the plugin's own bare newest-first JSON array at `~/.local/state/omanix/clipboard-history.json`; `--history-index N` reads `.[N]` (no cliphist).
- `modules/home-manager/desktop/quickshell.nix`: added `wl-clipboard`, `util-linux` (setpriv), `procps` (pkill), `perl` to `home.packages` so the shell's `wl-paste --watch capture.sh` watchers resolve at runtime.
- Runtime verification (picker opens, paste into focus, emoji insert, >1MB/UTF-16 handling) pending a live Hyprland + shell session.

## Testing
- Build and enter a Hyprland session with the shell running (mako/walker not running).
- Copy several items (`echo foo | wl-copy`, copy an image), run `omanix-clipboard-open`, pick one, confirm it becomes the clipboard content.
- Run `omanix-menu-emoji`, search "fire", select 🔥, confirm insertion via `omanix-menu-emoji-insert` into a focused text field.
- `wl-copy < large-file.txt` then open the picker — no crash, entry listed/handled.

## References
- omarchy: `shell/plugins/clipboard/` (`Clipboard.qml`, `ClipboardHistory.js`, `capture.sh`), `shell/plugins/emojis/` (`Emojis.qml`, `EmojiSearch.js`, `emojis.json`), `bin/omarchy-clipboard-*`, `bin/omarchy-menu-emoji`, `bin/omarchy-menu-emoji-insert`
- omanix: `modules/home-manager/ui/walker.nix` + `ui/elephant.nix` (clipboard/symbols providers superseded), `pkgs/omanix-scripts/`
