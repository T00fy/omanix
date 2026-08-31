# Q4-04: Network tools (`omanix-network-*`)

- **Phase:** 4
- **Status:** todo
- **Depends on:** none
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 added a Setup › Network toolset (surfaced in the shell's network panel and menu):
band pinning, Wi-Fi QR sharing, password reveal, live speed test, and a status line for the bar.
All are NetworkManager-based (`nmcli`/`iw`). Omanix uses NetworkManager already (recon: base
system enables it) and ships `wlctl` (a wifi TUI) but none of these helpers.

## Scope
**In scope:** port `omanix-network-{band,qr,password,speedtest,status}` and enterprise (802.1X)
Wi-Fi connect support. Register in `pkgs/omanix-scripts/default.nix`.
**Out of scope:** the shell network panel QML (ships with Q1-13's network plugin); replacing
`wlctl`.

## Implementation notes
- Port from omarchy `bin/omarchy-network-{band,qr,password,speedtest,status}`. Apply **D1**.
- **`omanix-network-band`** — show or pin the Wi-Fi band (`auto|2.4|5|6`) on the active
  connection via NetworkManager `802-11-wireless.band`; compute available bands from a cached
  scan; revert safely if reassociation fails. Deps: `networkmanager` (nmcli), `iw`.
- **`omanix-network-qr`** — build a `WIFI:` payload from the active connection's secrets and emit
  a QR via `qrencode`. Refuse enterprise/802.1X networks. Emits an ASCII matrix (0/1) for the
  shell; `--meta` header opt-in. Deps: `qrencode`, `networkmanager`.
- **`omanix-network-password`** — read the active Wi-Fi password (`nmcli -s -g 802-11-wireless-security.psk …`). Deps: `networkmanager`.
- **`omanix-network-speedtest`** — live down/up using Netflix/fast.com endpoints; parallel curl
  workers sampling `/sys/class/net/<iface>/statistics/*_bytes`. Deps: `curl`, `coreutils`.
- **`omanix-network-status`** — tab-separated type/ssid/signal/freq for the bar; `--verbose` adds
  iface/ip/gateway/bitrate + parallel router+internet ping latency. Deps: `networkmanager`, `iproute2`, `iputils`.
- Enterprise 802.1X connect: ensure the connect path supports EAP identity/password (nmcli
  `802-1x.*`). This may be a small addition to the connect helper the shell menu calls.
- These are pure runtime scripts — no NixOS options needed; NetworkManager is assumed present
  (assert/depend on it in the module that installs these).

## Acceptance criteria
- [ ] All five scripts ported (D1) and registered in `default.nix` with correct deps.
- [ ] `omanix-network-status` prints a valid tab-separated line for the active connection; `--verbose` adds the extended fields.
- [ ] `omanix-network-qr` produces a scannable QR for a PSK network and refuses an 802.1X network with a clear message.
- [ ] `omanix-network-band` lists available bands and pins/reverts without dropping the connection permanently.
- [ ] `omanix-network-speedtest` reports non-zero throughput on a connected machine.

## Testing
- `nix build .#omanix-scripts` and `nix flake check` pass.
- On a Wi-Fi-connected dev host: run each script and confirm sane output (`omanix-network-status`, `--verbose`, `omanix-network-password`, `omanix-network-qr | qrencode`-scan with a phone, `omanix-network-speedtest`).
- `omanix-network-band auto` then pin `5` — connection stays up; revert works.

## References
- omarchy: `bin/omarchy-network-{band,qr,password,speedtest,status}`
- omanix: `pkgs/omanix-scripts/default.nix`, `pkgs/omanix-scripts/src/`
