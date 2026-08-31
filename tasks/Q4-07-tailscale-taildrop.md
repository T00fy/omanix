# Q4-07: Tailscale taildrop send/receive

- **Phase:** 4
- **Status:** todo
- **Depends on:** none
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 added Taildrop file sharing over Tailscale: a `send` command and a
long-running `receive` systemd user service. Omanix has no equivalent. This ticket ports
both, reframed declaratively for NixOS. Tailscale itself is assumed available (a `services.tailscale`
NixOS option or the `tailscale` package); this ticket only adds the omanix send/receive UX
on top.

omarchy source:
- `bin/omarchy-tailscale-send` — `omarchy tailscale send <machine> [file...]`; sends via
  `tailscale file cp`; with no files, opens a file picker (`omarchy-file-select`); desktop
  notifications on success/failure.
- `bin/omarchy-tailscale-receive` — long-running receiver: `tailscale file get --wait
  --conflict=rename`, stages into `~/Downloads/.omarchy-taildrop`, then atomically claims the
  final name via `link(2)` (collision-safe), notifies (image preview for images, `xdg-open`
  action). Has a `--once` one-shot mode.
- `default/systemd/user/omarchy-tailscale-receive.service` — runs the receiver.

## Scope
**In scope:** ported `omanix-tailscale-send` and `omanix-tailscale-receive` scripts; a
`systemd.user.services.omanix-tailscale-receive` unit; a `omanix.tailscale.taildrop.enable`
option gating the receiver; a file-select helper if `omanix-file-select` doesn't exist yet
(check `pkgs/omanix-scripts/src/`).
**Out of scope:** installing/enabling Tailscale itself; the Quickshell tailscale bar
widget/panel (that ships with the vendored shell in Q1-13); exit-node UI.

## Implementation notes
- Add `omanix-tailscale-send.sh` and `omanix-tailscale-receive.sh` to
  `pkgs/omanix-scripts/src/` and wire them in `pkgs/omanix-scripts/default.nix` (follow the
  existing `wrapProgram` pattern; inject `tailscale`, `libnotify`/notification helper,
  `xdg-utils` as runtime deps).
- **D1:** rename `omarchy-*` → `omanix-*` throughout (notifications helper, file-select).
- Notifications: omanix currently uses `notify-send`/mako (being replaced by the shell's
  `omanix.notifications` in Q1-06). Use whatever notification entrypoint omanix standardizes
  on; for now `notify-send` is fine. Preserve the image-preview + `xdg-open` click action.
- Receiver service: reframe the omarchy systemd unit as a Nix `systemd.user.services` entry
  in a new HM module `modules/home-manager/desktop/tailscale.nix` (or under `apps/`). Gate on
  `omanix.tailscale.taildrop.enable` (default false). Use `Restart=on-failure`,
  `WantedBy=graphical-session.target`.
- Keep the atomic `link(2)` claim behavior (prevents partial-file races); the staging dir is
  `~/Downloads/.omanix-taildrop`.
- File picker: if `omanix-file-select` is missing, port omarchy's `bin/omarchy-file-select`
  (a small `omanix-menu`/fuzzel-driven picker) as part of this ticket.

## Acceptance criteria
- [ ] `omanix-tailscale-send <machine> <file>` sends a file and notifies on success/failure.
- [ ] `omanix-tailscale-send <machine>` with no file opens a picker.
- [ ] `omanix.tailscale.taildrop.enable = true` starts a `omanix-tailscale-receive` user
      service that saves incoming files to `~/Downloads` and notifies (image preview for images).
- [ ] Concurrent/duplicate-name transfers do not clobber (rename-on-conflict works).
- [ ] No `omarchy` strings remain in the ported scripts or unit.
- [ ] `nix flake check` passes; the new option appears in the generated options doc.

## Testing
- `nix build .#omanix-scripts` (or the attr that builds `pkgs/omanix-scripts`) succeeds.
- `nix flake check` passes.
- Manual (needs two tailnet machines or a loopback test): enable the receiver, send a file
  from another machine, confirm it lands in `~/Downloads` with a notification; send an image
  and confirm the preview + click-to-open.
- `omanix-tailscale-receive --once` exits after one transfer.

## References
- omarchy: `bin/omarchy-tailscale-send`, `bin/omarchy-tailscale-receive`,
  `bin/omarchy-file-select`, `default/systemd/user/omarchy-tailscale-receive.service`
- omanix: `pkgs/omanix-scripts/{default.nix,src/}`, new
  `modules/home-manager/desktop/tailscale.nix`
