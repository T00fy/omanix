{
  lib,
  stdenv,
  makeWrapper,
  python3,
  bash,
  coreutils,
  jq,
}:

# AI agent usage collectors + orchestrator (Q5-02). Feeds the omanix.agents
# Quickshell bar widget: each omanix-agent-usage-<agent> collector prints one
# display-ready JSON record, and omanix-agent-usage-update writes them to
# ~/.local/state/omanix/agents/usage/.
#
# The three collectors are stdlib-only Python 3 (argparse/urllib/sqlite3/fcntl/
# subprocess/… — no third-party deps); the orchestrator is bash. All reach
# external endpoints only when the matching agent is actually in use, and the
# codex collector self-skips when the codex CLI is not on PATH.
stdenv.mkDerivation {
  pname = "omanix-agent-usage";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp src/omanix-agent-usage-claude \
       src/omanix-agent-usage-codex \
       src/omanix-agent-usage-fireworks \
       src/omanix-agent-usage-update $out/bin/
    chmod +x $out/bin/omanix-agent-usage-*

    # The collectors ship an upstream #!/usr/bin/python3 shebang, which does not
    # exist on NixOS. patchShebangs resolves absolute-path interpreters against
    # $HOST_PATH (empty here), not build inputs, so it leaves this untouched;
    # rewrite it directly to the store interpreter (this also pins python3 as a
    # runtime dependency via the store-path reference).
    for c in claude codex fireworks; do
      substituteInPlace $out/bin/omanix-agent-usage-$c \
        --replace-fail '#!/usr/bin/python3' '#!${python3}/bin/python3'
    done
    runHook postInstall
  '';

  # patchShebangs fixes the python3 / bash interpreters. The updater then needs
  # jq + coreutils and the sibling collectors ($out/bin) on PATH.
  postFixup = ''
    wrapProgram $out/bin/omanix-agent-usage-update \
      --prefix PATH : $out/bin:${lib.makeBinPath [ bash coreutils jq ]}
  '';

  meta = with lib; {
    description = "AI agent usage collectors + orchestrator for the omanix.agents widget";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
