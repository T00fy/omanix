{
  lib,
  stdenv,
  makeWrapper,
  bash,
  xdg-utils,
  hyprland,
  jq,
  coreutils,
  ghostty,
  procps,
  systemd,
  walker,
  gawk,
  gnused,
  libxkbcommon,
  libnotify,
  swaybg,
  envsubst,
  glow,
  pavucontrol,
  hyprpicker,
  waybar,
  # Configurable options
  browserFallback ? "firefox.desktop",
  # Data files injected by the module
  themesJson ? null,
  docStylePreview ? null,
  docStyleOverride ? null,
  docStyleGeneral ? null,
  docsDir ? null,
  themeListFormatted ? "",
}:

stdenv.mkDerivation {
  pname = "omanix-scripts";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin

    # ═══════════════════════════════════════════════════════════════════
    # 1. omanix-launch-browser
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-browser.sh $out/bin/omanix-launch-browser
    chmod +x $out/bin/omanix-launch-browser
    wrapProgram $out/bin/omanix-launch-browser \
      --set OMANIX_BROWSER_FALLBACK "${browserFallback}" \
      --prefix PATH : ${lib.makeBinPath [ bash xdg-utils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 2. omanix-launch-or-focus
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-or-focus.sh $out/bin/omanix-launch-or-focus
    chmod +x $out/bin/omanix-launch-or-focus
    wrapProgram $out/bin/omanix-launch-or-focus \
      --prefix PATH : ${lib.makeBinPath [ bash hyprland jq coreutils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 3. omanix-launch-tui
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-tui.sh $out/bin/omanix-launch-tui
    chmod +x $out/bin/omanix-launch-tui
    wrapProgram $out/bin/omanix-launch-tui \
      --prefix PATH : ${lib.makeBinPath [ bash ghostty coreutils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 4. omanix-launch-or-focus-tui
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-or-focus-tui.sh $out/bin/omanix-launch-or-focus-tui
    chmod +x $out/bin/omanix-launch-or-focus-tui
    wrapProgram $out/bin/omanix-launch-or-focus-tui \
      --prefix PATH : "$out/bin:${lib.makeBinPath [ bash coreutils ]}"

    # ═══════════════════════════════════════════════════════════════════
    # 5. omanix-cmd-terminal-cwd
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-cmd-terminal-cwd.sh $out/bin/omanix-cmd-terminal-cwd
    chmod +x $out/bin/omanix-cmd-terminal-cwd
    wrapProgram $out/bin/omanix-cmd-terminal-cwd \
      --prefix PATH : ${lib.makeBinPath [ bash hyprland jq procps coreutils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 6. omanix-launch-walker
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-walker.sh $out/bin/omanix-launch-walker
    chmod +x $out/bin/omanix-launch-walker
    wrapProgram $out/bin/omanix-launch-walker \
      --set WALKER_BIN "${walker}/bin/walker" \
      --prefix PATH : ${lib.makeBinPath [ bash procps systemd coreutils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 7. omanix-smart-delete
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-smart-delete.sh $out/bin/omanix-smart-delete
    chmod +x $out/bin/omanix-smart-delete
    wrapProgram $out/bin/omanix-smart-delete \
      --prefix PATH : ${lib.makeBinPath [ bash hyprland jq ]}

    # ═══════════════════════════════════════════════════════════════════
    # 8. omanix-menu
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-menu.sh $out/bin/omanix-menu
    chmod +x $out/bin/omanix-menu
    wrapProgram $out/bin/omanix-menu \
      --set WALKER_BIN "${walker}/bin/walker" \
      --prefix PATH : "$out/bin:${lib.makeBinPath [
        bash coreutils hyprpicker libnotify systemd xdg-utils
      ]}"

    # ═══════════════════════════════════════════════════════════════════
    # 9. omanix-menu-style
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-menu-style.sh $out/bin/omanix-menu-style
    chmod +x $out/bin/omanix-menu-style
    wrapProgram $out/bin/omanix-menu-style \
      --set WALKER_BIN "${walker}/bin/walker" \
      ${lib.optionalString (themesJson != null) ''--set OMANIX_THEMES_FILE "${themesJson}"''} \
      ${lib.optionalString (docStylePreview != null) ''--set OMANIX_DOC_STYLE_PREVIEW "${docStylePreview}"''} \
      ${lib.optionalString (docStyleOverride != null) ''--set OMANIX_DOC_STYLE_OVERRIDE "${docStyleOverride}"''} \
      --prefix PATH : "$out/bin:${lib.makeBinPath [
        bash jq coreutils gnused envsubst swaybg ghostty glow
      ]}"

    # ═══════════════════════════════════════════════════════════════════
    # 10. omanix-menu-keybindings
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-menu-keybindings.sh $out/bin/omanix-menu-keybindings
    chmod +x $out/bin/omanix-menu-keybindings
    wrapProgram $out/bin/omanix-menu-keybindings \
      --prefix PATH : "$out/bin:${lib.makeBinPath [
        bash gawk libxkbcommon hyprland jq gnused coreutils
      ]}"

    # ═══════════════════════════════════════════════════════════════════
    # 11. omanix-show-style-help
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-show-style-help.sh $out/bin/omanix-show-style-help
    chmod +x $out/bin/omanix-show-style-help
    wrapProgram $out/bin/omanix-show-style-help \
      ${lib.optionalString (docStyleGeneral != null) ''--set OMANIX_DOC_STYLE "${docStyleGeneral}"''} \
      --set OMANIX_THEME_LIST "${themeListFormatted}" \
      --prefix PATH : ${lib.makeBinPath [
        bash coreutils gnused ghostty glow
      ]}

    # ═══════════════════════════════════════════════════════════════════
    # 12. omanix-show-setup-help
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-show-setup-help.sh $out/bin/omanix-show-setup-help
    chmod +x $out/bin/omanix-show-setup-help
    wrapProgram $out/bin/omanix-show-setup-help \
      ${lib.optionalString (docsDir != null) ''--set OMANIX_DOCS_DIR "${docsDir}"''} \
      --prefix PATH : ${lib.makeBinPath [
        bash ghostty glow coreutils
      ]}

    # ═══════════════════════════════════════════════════════════════════
    # 13. omanix-cmd-logout
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-cmd-logout.sh $out/bin/omanix-cmd-logout
    chmod +x $out/bin/omanix-cmd-logout
    wrapProgram $out/bin/omanix-cmd-logout \
      --prefix PATH : ${lib.makeBinPath [ bash hyprland jq coreutils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 14. omanix-restart-walker
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-restart-walker.sh $out/bin/omanix-restart-walker
    chmod +x $out/bin/omanix-restart-walker
    wrapProgram $out/bin/omanix-restart-walker \
      --prefix PATH : ${lib.makeBinPath [ bash systemd libnotify coreutils ]}

    # ═══════════════════════════════════════════════════════════════════
    # 15. omanix-launch-audio
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-audio.sh $out/bin/omanix-launch-audio
    chmod +x $out/bin/omanix-launch-audio
    wrapProgram $out/bin/omanix-launch-audio \
      --prefix PATH : ${lib.makeBinPath [ bash pavucontrol ]}

    # ═══════════════════════════════════════════════════════════════════
    # 16. omanix-launch-wifi
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-wifi.sh $out/bin/omanix-launch-wifi
    chmod +x $out/bin/omanix-launch-wifi
    wrapProgram $out/bin/omanix-launch-wifi \
      --prefix PATH : "$out/bin:${lib.makeBinPath [ bash ]}"

    # ═══════════════════════════════════════════════════════════════════
    # 17. omanix-launch-bluetooth
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-bluetooth.sh $out/bin/omanix-launch-bluetooth
    chmod +x $out/bin/omanix-launch-bluetooth
    wrapProgram $out/bin/omanix-launch-bluetooth \
      --prefix PATH : "$out/bin:${lib.makeBinPath [ bash ]}"

    # ═══════════════════════════════════════════════════════════════════
    # 18. omanix-toggle-waybar
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-toggle-waybar.sh $out/bin/omanix-toggle-waybar
    chmod +x $out/bin/omanix-toggle-waybar
    wrapProgram $out/bin/omanix-toggle-waybar \
      --prefix PATH : ${lib.makeBinPath [ bash procps waybar ]}
  '';

  meta = with lib; {
    description = "Core logic scripts for Omanix desktop environment";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
