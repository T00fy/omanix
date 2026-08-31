# Q4-03: Audio tuning subsystem (PipeWire filter-chain)

- **Phase:** 4
- **Status:** todo
- **Depends on:** none (uses Q4-02 `omanix-hw-intel-sof` if present; degrade gracefully)
- **Blocks:** none
- **Size:** L

## Context
Omarchy 4.0.2 replaced thin PulseAudio wrappers with a DSP-aware audio model: per-laptop speaker
EQ/limiter implemented as a **PipeWire filter-chain** hosted in its own systemd user service
(`omarchy-speaker-tuning.service`), plus helpers that resolve the *physical* sink underneath any
DSP/virtual sink so volume/mute act on the right node. Tunings are **data-driven** directories
under `default/audio/tunings/<model>/` matched by DMI/SKU/command. Omarchy ships one tuning,
`dell-xps-2026` (13-biquad + lookahead limiter, needs `lsp-plugins-lv2`).

Omanix today only has `omanix-cmd-audio-switch` (PulseAudio + swayosd). This ticket ports the
tuning framework and sink-resolution helpers, reframing the systemd user service declaratively.

## Scope
**In scope:** port `omanix-audio-tuning` (on|off|status|match|fronted-sink), the sink helpers
`omanix-audio-output-{sink,volume,set-default}`, `omanix-audio-{input-set-default,source-switch,sink-availability}`,
and `omanix-restart-audio` (wireplumber/pipewire restart + stuck-USB recovery). Ship the
`dell-xps-2026` tuning data. Provide the speaker-tuning user service as a Nix-managed unit.
**Out of scope:** authoring new tunings for other laptops; EasyEffects integration beyond
sink-resolution awareness.

## Implementation notes
- Port from omarchy `bin/omarchy-audio-*`, `bin/omarchy-restart-audio`,
  `default/audio/filter-chain-host.conf`, `default/audio/tunings/dell-xps-2026/{tuning.conf,filter-chain.conf}`,
  and `default/systemd/user/omarchy-speaker-tuning.service`. Apply **D1** to names/paths/service.
- **Service (declarative):** instead of shipping a `.service` file to `~/.config/systemd/user`,
  define it in the omanix home-manager module as `systemd.user.services.omanix-speaker-tuning`.
  The unit hosts a PipeWire filter-chain via `pipewire -c <filter-chain.conf>`; switching tuning
  on/off starts/stops the unit (no full audio restart — that's the design point).
- **Tuning data** ships in the store (read-only): a new `pkgs/omanix-audio-tunings/` (or under
  the shell/scripts pkg) exposing `tunings/<model>/{tuning.conf,filter-chain.conf}`. The
  `@SPEAKER_SINK@` placeholder in `filter-chain.conf` is substituted at runtime. `tuning.conf`
  keys: `match_dmi`/`match_sku`/`match_command`, `sink_pattern`, `description`.
- `omanix-audio-tuning match` selects a tuning by DMI/SKU (dell-xps-2026 matches SKU 0DB9/0DBA);
  `fronted-sink` reports the physical sink the tuning fronts. `sink-availability` hides that
  physical sink from the shell's device list while a tuning is active.
- Arch → Nix tool notes: `pactl`/`wpctl` come from `pipewire`/`wireplumber` (already in a
  PipeWire setup); `lsp-plugins-lv2` and `pipewire` filter-chain module must be present —
  declare them. `usbreset` (from `usbutils`) for stuck-USB recovery in `omanix-restart-audio`.
- Gate the whole subsystem behind an option, e.g. `omanix.audio.speakerTuning.enable` (default
  false), and only wire the service + `lsp-plugins-lv2` when enabled.
- `omanix-audio-output-volume` shows the OSD — call `omanix-osd` (Q1-07) if present, else
  degrade to swayosd during the transition.

## Acceptance criteria
- [ ] `omanix-audio-tuning {on,off,status,match,fronted-sink}` ported (D1) and registered in `default.nix`.
- [ ] Sink helpers (`output-sink`, `output-volume`, `output-set-default`, `input-set-default`, `source-switch`, `sink-availability`) ported and registered.
- [ ] `omanix-restart-audio` ported, including USB device recovery path.
- [ ] `dell-xps-2026` tuning data shipped in the store and resolvable by `omanix-audio-tuning match` on a matching machine.
- [ ] Speaker-tuning service defined declaratively as `systemd.user.services.omanix-speaker-tuning`, gated behind `omanix.audio.speakerTuning.enable`.
- [ ] `lsp-plugins-lv2` only pulled in when the option is enabled.

## Testing
- `nix build .#omanix-scripts` and `nix flake check` pass.
- With the option disabled: no speaker-tuning unit, no `lsp-plugins-lv2` in the closure.
- With the option enabled on any host: `systemctl --user status omanix-speaker-tuning` shows the unit; `omanix-audio-tuning status` reflects on/off; toggling does not restart pipewire.
- `omanix-audio-output-volume up/down/mute` changes volume on the resolved physical sink (`wpctl status` before/after).
- On a non-Dell host, `omanix-audio-tuning match` returns no match cleanly (no error).

## References
- omarchy: `bin/omarchy-audio-tuning`, `bin/omarchy-audio-output-{sink,volume,set-default}`, `bin/omarchy-audio-{input-set-default,source-switch,sink-availability}`, `bin/omarchy-restart-audio`, `default/audio/filter-chain-host.conf`, `default/audio/tunings/dell-xps-2026/`, `default/systemd/user/omarchy-speaker-tuning.service`, `docs/AUDIO-TUNING.md`
- omanix: `pkgs/omanix-scripts/`, `modules/home-manager/` (audio module — create if absent), `modules/nixos/default.nix` (PipeWire/lsp deps)
