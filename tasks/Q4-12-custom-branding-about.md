# Q4-12: Custom system branding — About screen + logo→ANSI

- **Phase:** 4
- **Status:** todo
- **Depends on:** none
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 ships a **custom branding** feature: a `neofetch`-style **About** screen and a
matching **screensaver** banner, both of which display an ANSI-art logo the user can replace with
any image (e.g. a company logo like 37signals). The transcript calls this out under "Custom System
Branding" — the user wants it in omanix. omanix already ships the screensaver
(`pkgs/omanix-screensaver/`), so this ticket adds the branding layer (About screen + swappable
logo) and wires the screensaver banner to it.

Upstream implements this with:
- `bin/omarchy-branding-about` — set/edit/reset the About logo (`~/.config/omarchy/branding/about.txt`).
- `bin/omarchy-branding-screensaver` — set/edit/reset the screensaver banner (`~/.config/omarchy/branding/screensaver.txt`).
- `bin/omarchy-transcode-ascii` — convert a PNG/SVG to ANSI art (used by both, sized via `--width/--height`).
- `bin/omarchy-launch-about` — render the About screen; defaults live at `$OMARCHY_PATH/{icon.txt,logo.txt}`.

## Scope
**In scope:** port `omanix-branding-about`, `omanix-branding-screensaver`, `omanix-transcode-ascii`,
and the About launcher (`omanix-launch-about` or fold into an existing omanix about/fastfetch view
if one exists). Ship the default `icon.txt`/`logo.txt` (renamed to omanix branding, D1). Wire the
existing screensaver (`pkgs/omanix-screensaver/`) to read the branding banner. Provide a
**declarative default** for the logo and a runtime override that follows the D2/Q1-03 pattern.
**Out of scope:** the image transcoding-to-JPEG feature (that's `omanix-transcode` in Q4-05 — a
different tool); the screensaver engine itself (already in omanix).

## Implementation notes
- Port the three scripts + launcher from omarchy, applying **D1** (`omarchy`→`omanix`,
  `OMARCHY_PATH`→`OMANIX_PATH`, `~/.config/omarchy`→`~/.config/omanix`). Register in
  `pkgs/omanix-scripts/default.nix`.
- **`omanix-transcode-ascii`** — image (PNG/SVG) → ANSI art at a target width/height. Confirm the
  upstream engine (likely `chafa`, possibly ImageMagick for SVG rasterization) and use the same;
  add it to the script's deps.
- **Branding state files** — `~/.config/omanix/branding/{about,screensaver}.txt` are user-writable
  (the `text` subcommand opens them in `$EDITOR`; `image` regenerates them; `reset` restores the
  default). Treat them exactly like `shell.json`: seed from a **declared default** and never
  symlink into the store. If a declared option is added (see next bullet), reconcile per the
  **Q1-03 declarative reconcile contract** (declared value wins on rebuild; a runtime `image`/`text`
  edit is an ephemeral overlay). If no option is set, the declared default is just the omanix
  `icon.txt`/`logo.txt`.
- **Declarative option (recommended, D4-aligned):** add `omanix.branding.logo` (nullable path to a
  PNG/SVG, default null). When set, activation transcodes it to the branding `.txt` default at
  build/activation time so a user can declare their logo in the flake; the runtime
  `omanix-branding-*` commands remain available as the ephemeral overlay. Keep it optional — the
  feature must work with no option set (falls back to the omanix default logo).
- **About screen** — check whether omanix already has an about/fastfetch surface before adding a new
  launcher; if not, port `omarchy-launch-about`. It reads the branding `about.txt` for the logo.
- **Screensaver wiring** — `pkgs/omanix-screensaver/` should read `~/.config/omanix/branding/screensaver.txt`
  (falling back to the shipped default) so a branded logo shows in the screensaver, matching upstream.
- `omanix-branding-*` call `omanix-file-select` and `omanix-launch-editor`/`omanix-launch-screensaver`
  — map these to the omanix equivalents (file picker + `$EDITOR` launcher + the existing screensaver
  launcher).

## Acceptance criteria
- [ ] `omanix-transcode-ascii` converts a PNG/SVG to sized ANSI art.
- [ ] `omanix-branding-about image|text|reset` sets/edits/resets the About logo; `reset` restores the shipped omanix default.
- [ ] `omanix-branding-screensaver image|text|reset` does the same for the screensaver banner, and the screensaver renders it.
- [ ] The About screen displays the current branding logo.
- [ ] Branding state files are user-writable copies (never store symlinks); on a fresh machine they seed from the declared default.
- [ ] If `omanix.branding.logo` is implemented: setting it in the flake produces a branded default; leaving it null falls back to the omanix logo. Runtime edits behave as an ephemeral overlay (revert on rebuild).
- [ ] `nix build .#omanix-scripts` and `nix flake check` pass; options doc builds (if an option is added).

## Testing
```bash
cd /home/toofy/projects/omanix
nix build .#omanix-scripts
nix flake check
```
Runtime (Hyprland session):
- `omanix-branding-about image` → pick a PNG → About screen shows the new logo.
- `omanix-branding-screensaver image` → pick a PNG → launch the screensaver, confirm the banner.
- `omanix-branding-about reset` restores the default logo.
- If the option exists: set `omanix.branding.logo`, rebuild → default logo reflects it; runtime `image` override reverts on the next rebuild.

## References
- omarchy: `bin/omarchy-branding-about`, `bin/omarchy-branding-screensaver`, `bin/omarchy-transcode-ascii`, `bin/omarchy-launch-about`, `$OMARCHY_PATH/{icon.txt,logo.txt}`
- omanix: `pkgs/omanix-scripts/`, `pkgs/omanix-screensaver/`, Q1-03 (reconcile contract), Q4-05 (`omanix-transcode`, the JPEG tool — not this one)
