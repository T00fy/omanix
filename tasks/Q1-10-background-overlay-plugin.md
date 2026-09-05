# Q1-10: Background overlay plugin

- **Phase:** 1
- **Status:** done
- **Depends on:** Q1-04
- **Blocks:** Q3-02
- **Size:** S

## Resolution
Enabled by seeding `~/.local/state/omanix/current/background` as a writable symlink to the
declared `config.omanix.activeTheme.assets.wallpaper` via a new `home.activation.omanixBackgroundState`
step in `modules/home-manager/desktop/quickshell.nix`. `Background.qml` resolves its image with
`readlink -f` on that link at startup. The plugin auto-loads as a first-party `service` (kind
`service`, id `omanix.background`, IPC target `background`, layershell namespace `omanix-background`)
because it is absent from `disabledPlugins[]` — so no QML edit, no new option, and no `shell.json`
config block were needed. Chosen approach = ticket option (a) (point at the store wallpaper),
adapted to the plugin's real mechanism (state symlink, not a config key); D2-aligned since a
runtime switcher may repoint the link ephemerally and each rebuild reasserts the declared theme.
swaybg autostart + `hyprpaper.nix` left in place — their removal is Q3-02. `nix flake check` and
`nix build .#omanix-shell` pass.

## Context
Omarchy 4.0.2 draws the desktop wallpaper from inside the Quickshell process via the
`omarchy.background` overlay plugin, replacing standalone wallpaper daemons. Omanix today
sets the wallpaper with `swaybg` (launched from Hyprland autostart) plus a `hyprpaper.nix`
module. This ticket brings up the in-shell background overlay as `omanix.background` so the
shell owns the wallpaper, matching the rest of the Phase 1 plugin stack.

The overlay is a fullscreen `overlay`-kind plugin. It is marked `keepLoaded` so it stays
resident between summons rather than being torn down (it must persist as long as the desktop
is visible). It is closely related to the image-picker overlay (`omarchy.image-picker`,
handled elsewhere): the picker chooses a background and the background overlay renders it;
the two share the notion of the "current background" file.

## Scope
**In scope:** vendor + enable the `omanix.background` overlay plugin so the wallpaper is drawn
by the shell; wire the current-wallpaper source to omanix's existing theme/wallpaper resolution
(`omanix.activeTheme.assets.wallpaper`); ensure it is enabled by default in the seeded
`shell.json`.
**Out of scope:** the image-picker overlay and background switcher CLIs (`omanix-theme-bg-*`,
Q2-05); removing the old swaybg autostart / `hyprpaper.nix` (done in Q3-02/Q3-03 once this is
proven).

## Implementation notes
- Source lives at omarchy `shell/plugins/background/{Background.qml,manifest.json}` — vendored
  into `pkgs/omanix-shell` by Q1-02 with the D1 rename applied (`omarchy.background` →
  `omanix.background`).
- **D1:** confirm the manifest `id` and any IPC target became `omanix.background` after the
  rename patch; the overlay registers its own IPC target named `background` (verify the exact
  target string post-rename).
- The background image path: omarchy reads the current background from user state
  (`~/.config/omarchy/…` / the theme's background dir). For omanix, feed the declared wallpaper
  from `config.omanix.activeTheme.assets.wallpaper` (resolved in
  `modules/home-manager/theme/default.nix`). Decide whether to (a) point the plugin's expected
  background path at the store wallpaper via seeded config, or (b) copy it into the writable
  state dir on activation. Prefer (a) for declarativeness; document the choice.
- `keepLoaded: true` must survive the rename — do not strip it.
- Enablement: the overlay should be active by default. Built-in plugins are on unless listed in
  `disabledPlugins[]` of `shell.json`; ensure it is not disabled.

## Acceptance criteria
- [ ] `omanix.background` plugin is present in the vendored shell and passes the shell's plugin
      validation (loads without error in the running shell).
- [ ] On login to a Hyprland session with the shell running, the declared theme wallpaper is
      displayed by the shell (not by swaybg).
- [ ] The wallpaper shown matches `config.omanix.activeTheme.assets.wallpaper` for the selected
      theme; switching the declared theme + rebuild changes the wallpaper.
- [ ] `keepLoaded` behavior verified: the background stays rendered across menu/panel summons.
- [ ] `nix flake check` passes and the options doc still builds.

## Testing
- Build: `nix build .#omanix-shell` (or the shell package attr) and `nix flake check`.
- Runtime/visual: start a Hyprland session with the shell autostarted; confirm the wallpaper
  renders full-screen and matches the declared theme. Summon the launcher/a panel and confirm
  the background persists.
- Confirm no `swaybg` process is required for the wallpaper to appear (you may temporarily
  disable the old autostart locally to prove the shell draws it; the permanent removal is Q3-02).

## References
- omarchy: `shell/plugins/background/Background.qml`, `shell/plugins/background/manifest.json`,
  `docs/omarchy-shell.md` (overlay + keepLoaded semantics)
- omanix: `modules/home-manager/desktop/hyprpaper.nix`,
  `modules/home-manager/desktop/hyprland/autostart.nix` (line ~36, swaybg),
  `modules/home-manager/theme/default.nix` (`activeTheme.assets.wallpaper`),
  seeded `shell.json` from Q1-03
