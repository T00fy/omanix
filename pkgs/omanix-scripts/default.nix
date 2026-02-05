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
  # Configurable options
  browserFallback ? "firefox.desktop",
}:

stdenv.mkDerivation {
  pname = "omanix-scripts";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin

    # Helper paths
    local_bin_path="${
      lib.makeBinPath [
        bash
        coreutils
      ]
    }"

    # ═══════════════════════════════════════════════════════════════════
    # 1. omanix-launch-browser
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-browser.sh $out/bin/omanix-launch-browser
    chmod +x $out/bin/omanix-launch-browser
    wrapProgram $out/bin/omanix-launch-browser \
      --set OMANIX_BROWSER_FALLBACK "${browserFallback}" \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          xdg-utils
        ]
      }

    # ═══════════════════════════════════════════════════════════════════
    # 2. omanix-launch-or-focus
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-or-focus.sh $out/bin/omanix-launch-or-focus
    chmod +x $out/bin/omanix-launch-or-focus
    wrapProgram $out/bin/omanix-launch-or-focus \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          hyprland
          jq
          coreutils
        ]
      }

    # ═══════════════════════════════════════════════════════════════════
    # 3. omanix-launch-tui
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-tui.sh $out/bin/omanix-launch-tui
    chmod +x $out/bin/omanix-launch-tui
    wrapProgram $out/bin/omanix-launch-tui \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          ghostty
          coreutils
        ]
      }

    # ═══════════════════════════════════════════════════════════════════
    # 4. omanix-launch-or-focus-tui
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-or-focus-tui.sh $out/bin/omanix-launch-or-focus-tui
    chmod +x $out/bin/omanix-launch-or-focus-tui
    # Note: We include $out/bin in the PATH so it can call scripts 2 and 3
    wrapProgram $out/bin/omanix-launch-or-focus-tui \
      --prefix PATH : "$out/bin:${
        lib.makeBinPath [
          bash
          coreutils
        ]
      }"

    cp src/omanix-cmd-terminal-cwd.sh $out/bin/omanix-cmd-terminal-cwd
    chmod +x $out/bin/omanix-cmd-terminal-cwd
    wrapProgram $out/bin/omanix-cmd-terminal-cwd \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          hyprland
          jq
          procps
          coreutils
        ]
      }

    # ═══════════════════════════════════════════════════════════════════
    # 6. omanix-launch-walker
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-launch-walker.sh $out/bin/omanix-launch-walker
    chmod +x $out/bin/omanix-launch-walker
    wrapProgram $out/bin/omanix-launch-walker \
      --set WALKER_BIN "${walker}/bin/walker" \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          procps
          systemd
          coreutils
        ]
      }
    # ═══════════════════════════════════════════════════════════════════
    # 7. omanix-smart-delete
    # ═══════════════════════════════════════════════════════════════════
    cp src/omanix-smart-delete.sh $out/bin/omanix-smart-delete
    chmod +x $out/bin/omanix-smart-delete
    wrapProgram $out/bin/omanix-smart-delete \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          hyprland
          jq
        ]
      }
  '';

  meta = with lib; {
    description = "Core logic scripts for Omanix desktop environment";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
