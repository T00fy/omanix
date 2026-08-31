# Q4-08: Gaming — Battle.net + RetroArch retro

- **Phase:** 4
- **Status:** todo
- **Depends on:** none
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 added two gaming helpers: a standalone Battle.net installer (no Steam/Lutris)
and RetroArch retro-console tooling. Omanix has `modules/nixos/steam.nix` but nothing for
these. This ticket ports both, reframing imperative "installers" into NixOS
packages/options where sensible and keeping thin per-user launcher scripts where the flow is
inherently runtime (ROM/prefix selection).

omarchy source:
- `bin/omarchy-install-gaming-battlenet` — installs Battle.net via `umu-launcher` +
  GE-Proton into `~/Games/battlenet`; downloads the official installer, detects/wipes partial
  prefixes, writes a `battlenet.desktop`. `bin/omarchy-remove-gaming-battlenet` reverses it.
- `bin/omarchy-games-retro-install` — creates a `.desktop` launcher for a RetroArch ROM;
  interactive core + ROM picker or `<core> <rom>`; runs `retroarch -L <core> <rom>`.
- `bin/omarchy-games-retro-cores` — lists installed libretro cores from `/usr/lib/libretro`,
  mapped to a curated ~22-system label list (SNES/snes9x, GBA/mgba, N64, PSX, PSP, Dreamcast,
  Saturn, Amiga, C64, MAME, …).

## Scope
**In scope:** a `omanix.gaming` module providing `battlenet.enable` (packages umu-launcher +
proton-ge, ships the launcher) and `retroarch.enable` (packages retroarch + a chosen core
set); ported `omanix-games-retro-{install,cores}` scripts; ported `omanix-*-gaming-battlenet`
launcher/removal where still needed at runtime.
**Out of scope:** Steam (already in `modules/nixos/steam.nix`); Lutris/Heroic; cloud gaming
(geforce-now/xbox); controller tuning.

## Implementation notes
- New module `modules/home-manager/apps/gaming.nix` (or `modules/nixos/gaming.nix` if it
  needs system-level Proton). Model options after existing `modules/nixos/steam.nix`.
- **Battle.net:** on Nix, package `umu-launcher` (in nixpkgs) and GE-Proton
  (`proton-ge-custom`/`proton-ge-bin` via nixpkgs or a fetch) declaratively rather than
  downloading at runtime. The *Battle.net installer .exe* itself is not redistributable, so
  keep a thin `omanix-gaming-battlenet` launcher script that runs the official installer
  through umu into `~/Games/battlenet` (prefix under `$HOME`, user-mutable). Ship a
  `battlenet.desktop`. Retain the partial-prefix detection.
- **RetroArch:** enable `programs.retroarch` / package `retroarch` with `libretroCores` (nix
  lets you pick cores declaratively — this replaces omarchy's `/usr/lib/libretro` scan). Port
  `omanix-games-retro-cores` to read the nix-provided core dir (resolve via the retroarch
  package rather than a hardcoded `/usr/lib/libretro`) and keep the curated label map. Port
  `omanix-games-retro-install` to generate a per-ROM `.desktop` (in
  `~/.local/share/applications`) using the omanix menu picker for core+ROM.
- **D1:** rename all `omarchy-*` → `omanix-*`.
- Gotcha: hardcoded `/usr/lib/libretro` must become a nix store path (derive from the
  retroarch/cores package). Do not hardcode a store hash — resolve at build via the package.

## Acceptance criteria
- [ ] `omanix.gaming.battlenet.enable = true` makes umu-launcher + GE-Proton available and
      installs a `omanix-gaming-battlenet` launcher + desktop entry.
- [ ] `omanix.gaming.retroarch.enable = true` installs retroarch with the configured cores.
- [ ] `omanix-games-retro-cores` lists the installed cores with friendly labels (no
      `/usr/lib/libretro` hardcode).
- [ ] `omanix-games-retro-install <core> <rom>` produces a working `.desktop` that launches
      the ROM; interactive mode opens a picker.
- [ ] No `omarchy` strings remain.
- [ ] `nix flake check` passes; new options appear in the generated options doc.

## Testing
- `nix build` the gaming module's packages; `nix flake check` passes.
- Enable retroarch, run `omanix-games-retro-cores` — confirm cores listed match the enabled
  set.
- `omanix-games-retro-install` with a test ROM produces a launcher that opens RetroArch with
  the right core.
- Battle.net: (manual, network) launcher opens the installer via umu; prefix created under
  `~/Games/battlenet`.

## References
- omarchy: `bin/omarchy-install-gaming-battlenet`, `bin/omarchy-remove-gaming-battlenet`,
  `bin/omarchy-games-retro-install`, `bin/omarchy-games-retro-cores`
- omanix: `modules/nixos/steam.nix` (reference), new
  `modules/home-manager/apps/gaming.nix`, `pkgs/omanix-scripts/{default.nix,src/}`
- nixpkgs: `umu-launcher`, `retroarch`/`libretro.*`, `proton-ge-*`
