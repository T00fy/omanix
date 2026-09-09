# Q4-09: Plymouth boot-splash theming

- **Phase:** 4
- **Status:** done
- **Depends on:** Q2-01
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 themes the Plymouth boot/unlock splash to match the active theme, with a
switcher over themes that ship an unlock preview. Omanix has no Plymouth theming. This ticket
ports it using the **hybrid pattern from D2**: Nix builds the Plymouth theme declaratively
from the palette (reproducible, applied on rebuild), and a runtime switcher is an ephemeral
overlay that reverts on the next rebuild.

omarchy source:
- `bin/omarchy-plymouth-set` (~412 lines) — builds the Plymouth theme (and matching SDDM
  theme) in a root-owned staging dir, recolors bullet/entry/lock/progress PNGs with
  ImageMagick, patches `omarchy.script` background colors + SDDM `Main.qml`, then runs
  `plymouth-set-default-theme` + `mkinitcpio -P`. Heavy privilege hardening (opens the logo fd
  before elevating, rejects symlinks, validates root-owned non-world-writable dirs, 64 MiB
  asset cap, dev-checkout exception via `/etc/omarchy.conf`).
- `bin/omarchy-plymouth-list` — lists themes shipping a `preview-unlock.png`.
- `bin/omarchy-plymouth-current` — identifies the active theme by byte-comparing installed
  `logo.png` against each theme's `unlock.png`.
- `bin/omarchy-plymouth-switcher` — image-menu picker over unlock previews.
- Themes ship `unlock.png` / `preview-unlock.png` assets.

## Scope
**In scope:** declarative Nix build of an omanix Plymouth theme colored from the active
palette; a `omanix.boot.plymouth.enable` option; ported `omanix-plymouth-{list,current,switcher}`
+ a runtime-only `omanix-plymouth-set` that swaps the *ephemeral* active theme; per-theme
`unlock.png`/`preview-unlock.png` assets.
**Out of scope:** SDDM theming (omanix uses SilentSDDM via `modules/nixos/login.nix` — note
but don't rework here); the omarchy privilege-hardening dance (Nix builds as root in the
sandbox, so most of it is moot — see notes).

## Implementation notes
- **Declarative build (the important part):** on Nix, `boot.plymouth` handles theme
  installation into the initrd. Build a themed Plymouth theme derivation colored from the
  palette produced by Q2-01 (`colors.toml`). Use `boot.plymouth.themePackages` +
  `boot.plymouth.theme`. This *replaces* omarchy's runtime `mkinitcpio -P` recolor step — the
  initrd is rebuilt by `nixos-rebuild`, not by a script.
- **The omarchy privilege hardening mostly evaporates** under Nix: the theme is built in the
  sandbox and installed into the store/initrd declaratively; there is no root-owned staging
  dir or `pkexec` step. Capture that reframing in the ticket rather than porting the guards.
- **Runtime switcher (ephemeral, D2):** `omanix-plymouth-{list,current,switcher}` operate over
  the set of themes omanix builds. `omanix-plymouth-set` may swap the active theme at runtime
  (`plymouth-set-default-theme -R` / regenerate initrd) but this is ephemeral — a
  `nixos-rebuild` reverts to `boot.plymouth.theme`. Document this clearly; it mirrors how
  Q2-* handles theme switching.
- Assets: add `unlock.png` + `preview-unlock.png` per theme under `assets/` (or the theme
  data in `lib/themes.nix`). At minimum generate a colored logo from the palette.
- **D1:** rename `omarchy-*` → `omanix-*`, `omarchy.script` → `omanix.script`.
- Gotcha: ImageMagick recoloring can move to build time (a derivation that recolors PNGs from
  the palette) rather than a runtime script — prefer that for reproducibility.

## Resolution — fully declarative, opt-out (default on)

Ported the **declarative half only**, per an explicit scope decision: on NixOS the boot
splash lives in the declaratively-built initrd (no persistent Arch-style
`plymouth-set-default-theme -R` + `mkinitcpio` path), so omarchy's D2 *ephemeral runtime
switcher* has no honest home here. The four `omanix-plymouth-{set,list,current,switcher}`
CLIs, the `unlock.png`/`preview-unlock.png` assets, and the ImageMagick PNG-recolor of
hand-authored art were **dropped** — the splash is generated programmatically from the
palette (solid background + accent progress bar, no art). The single source of truth is
`omanix.theme` + rebuild.

Delivered:
- `lib/plymouth.nix` — pure renderer (`omanixLib.renderPlymouthTheme`): a `script`-module
  `.plymouth` + `.script` colored from `{ colors, name }`, plus the two swatch colors
  (`trackColor` = darkened bg, `fillColor` = accent) the build materializes as 1×1 PNGs.
- `modules/nixos/plymouth.nix` — `omanix.boot.plymouth.enable` (**default `true`**, matching
  the other system toggles), builds the active theme's splash via `pkgs.runCommand` +
  `imagemagick`, wires `boot.plymouth.{enable,themePackages,theme}` and adds `quiet`/`splash`
  kernel params. Registered in `modules/nixos/default.nix`.
- Docs: Plymouth section in `docs/configuration.md`; the option renders in the generated
  options doc.

The omarchy privilege-hardening (root staging, symlink rejection, 64 MiB cap, `pkexec`)
evaporates: the theme is built in the Nix sandbox and installed into the store/initrd.
SDDM theming left untouched as directed. Logo deferred to Q4-12 (omanix has no logo asset
yet) — the splash is background + progress only.

## Acceptance criteria
- [x] `omanix.boot.plymouth.enable = true` builds and installs a Plymouth theme colored from
      the active palette; boot splash matches the theme after `nixos-rebuild` + reboot
      (build verified; splash appearance is runtime-only to verify).
- [x] Switching `omanix.theme` and rebuilding changes the boot splash colors (declarative).
- [ ] ~~`omanix-plymouth-{list,current,switcher}` CLIs~~ — **dropped** (declarative only; see Resolution).
- [ ] ~~Runtime `omanix-plymouth-set` ephemeral overlay~~ — **dropped** (declarative only; see Resolution).
- [x] No `omarchy` strings remain.
- [x] `nix flake check` passes; the option appears in the generated options doc.

## Testing
- `nix build` the plymouth theme derivation; `nix flake check` passes.
- Build a test system config with `omanix.boot.plymouth.enable = true`, rebuild, reboot in a
  VM — confirm the themed splash.
- Change theme, rebuild — confirm splash color changes.
- Run switcher at runtime, then rebuild — confirm revert.

## References
- omarchy: `bin/omarchy-plymouth-set`, `bin/omarchy-plymouth-list`,
  `bin/omarchy-plymouth-current`, `bin/omarchy-plymouth-switcher`
- omanix: `lib/themes.nix`, `modules/nixos/login.nix` (SilentSDDM, adjacent), new
  `modules/nixos/plymouth.nix`, `assets/`
- NixOS: `boot.plymouth.{enable,theme,themePackages}`
- Depends on Q2-01 for the per-theme `colors.toml`.
