# Q4-05: Capture tools (QR / region / OCR / webcam)

- **Phase:** 4
- **Status:** todo
- **Depends on:** none
- **Blocks:** Q4-02 (`omanix-hw-webcam` calls `omanix-capture-webcam-list`)
- **Size:** M

## Context
Omarchy 4.0.2 expanded screen-capture beyond screenshots/recordings: QR decode from a selected
region, a keyboard-navigable region picker, on-screen OCR, and webcam capture (list/resize/record
with webcam overlay). Omanix already has `omanix-cmd-screenshot` and `omanix-cmd-screenrecord`
(recon) using grim/slurp/wl-screenrec/wayfreeze; this ticket adds the new capture primitives and
relates them to the existing commands.

## Scope
**In scope:** port `omanix-capture-{qr,region,text,webcam-list,webcam-resize,screenrecording-with-webcam}`.
Register in `pkgs/omanix-scripts/default.nix`.
**Out of scope:** reworking the existing `omanix-cmd-screenshot`/`-screenrecord` (only touch them
if the ported webcam recording needs to hook into them).

## Implementation notes
- Port from omarchy `bin/omarchy-capture-{qr,region,text,webcam-list,webcam-resize,screenrecording-with-webcam}`.
  Apply **D1**. Note omarchy renamed `omarchy-capture-text-extraction` → `omarchy-capture-text`.
- **`omanix-capture-qr`** — freeze screen (`hyprpicker`), `grim` a `slurp`-selected region, decode
  with `zbarimg` restricted to QR only, copy result via `wl-copy --sensitive` (never print/log —
  QRs often carry secrets). Deps: `hyprpicker`, `grim`, `slurp`, `zbar` (zbarimg), `wl-clipboard`.
- **`omanix-capture-region`** — region picker with keyboard window-capture (Return/Tab/arrows).
  Deps: `slurp`, `grim`, `hyprland` (window geometry via `hyprctl`), `jq`.
- **`omanix-capture-text`** — OCR of a selected region. Deps: `grim`, `slurp`, `tesseract` (confirm
  which OCR engine omarchy uses; port the same), `wl-clipboard`.
- **`omanix-capture-webcam-list`** — list `/dev/video*` that actually support Video Capture via
  `v4l2-ctl`. Deps: `v4l-utils`. This is what `omanix-hw-webcam` (Q4-02) checks.
- **`omanix-capture-webcam-resize`** — resize the "WebcamOverlay" Hyprland window through 8:9
  portrait presets (small/medium/large + smaller/larger/reset). Deps: `hyprland`, `jq`.
- **`omanix-capture-screenrecording-with-webcam`** — screen recording with a webcam overlay;
  webcam offered only when a webcam is present. Reuse omanix's existing screenrecord logic where
  possible. Deps: `wl-screenrec`, `v4l-utils`, plus the webcam-overlay window (Hyprland rule +
  something like `mpv`/`wf-recorder` — port omarchy's approach exactly).
- Register each in `default.nix` with the deps above; several deps (grim/slurp/wl-clipboard/
  wl-screenrec/hyprpicker) are already inputs to the scripts package.

## Acceptance criteria
- [ ] All six scripts ported (D1) and registered with correct deps.
- [ ] `omanix-capture-qr` decodes a QR shown on screen and places it on the clipboard *marked sensitive*, without printing it to stdout/logs.
- [ ] `omanix-capture-webcam-list` lists only true capture devices; returns empty (clean exit) when none present.
- [ ] `omanix-capture-text` OCRs a region of on-screen text to the clipboard.
- [ ] `omanix-capture-region` supports both drag-select and keyboard window selection.
- [ ] Webcam recording is only offered when `omanix-capture-webcam-list` is non-empty.

## Testing
- `nix build .#omanix-scripts` and `nix flake check` pass.
- Runtime in a Hyprland session: display a QR (e.g. `qrencode -o - … | imv`), run `omanix-capture-qr`, paste and confirm; confirm stdout stays empty.
- `omanix-capture-text` on a terminal region returns recognizable text.
- `omanix-capture-webcam-list` output matches `v4l2-ctl --list-devices`.

## References
- omarchy: `bin/omarchy-capture-{qr,region,text,webcam-list,webcam-resize,screenrecording-with-webcam}`, `bin/omarchy-capture-screenshot`, `bin/omarchy-capture-screenrecording`
- omanix: `pkgs/omanix-scripts/default.nix`, `pkgs/omanix-scripts/src/omanix-cmd-screenshot.sh`, `pkgs/omanix-scripts/src/omanix-cmd-screenrecord.sh`
