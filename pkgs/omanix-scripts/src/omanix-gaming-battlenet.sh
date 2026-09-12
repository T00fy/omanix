#!/usr/bin/env bash

# omanix:summary=Install and launch Battle.net through umu + GE-Proton
# omanix:group=games
# omanix:examples=omanix-gaming-battlenet install

set -euo pipefail

# Declarative-Nix note: this is the one deliberate runtime download in the tree.
# It runs ONLY when omanix.gaming.battlenet.enable is set (opt-in, off by
# default), and only umu-launcher + GE-Proton — which it needs — come from
# nixpkgs/the flake. The Battle.net installer itself is proprietary and
# non-redistributable, so it cannot be pinned as a Nix package or checksummed
# against a stable artifact (the URL serves a live, moving installer). It
# installs into a mutable Wine prefix under ~/Games, which is inherently
# runtime state. This exception is intentional, not an oversight.
prefix="$HOME/Games/battlenet"
launcher="$prefix/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe"
installer_url="https://www.battle.net/download/getInstallerForGame?os=win&locale=enUS&version=LIVE&gameProgram=BATTLENET_APP"

export GAMEID="umu-battlenet"
export STORE="none"
export WINEPREFIX="$prefix"
export PROTONPATH="${OMANIX_PROTON_PATH:-}"

die() {
  echo "$1" >&2
  exit 1
}

require_runtime() {
  command -v umu-run >/dev/null 2>&1 || die "umu-run not found (enable omanix.gaming.battlenet)."
  [[ -n $PROTONPATH ]] || die "GE-Proton not configured (enable omanix.gaming.battlenet)."
}

usage() {
  cat <<'EOF'
Usage: omanix-gaming-battlenet <command>

Commands:
  install   Download and run the official Battle.net installer through umu.
  play      Launch the installed Battle.net client.
  remove    Delete the Battle.net Proton prefix (~/Games/battlenet).
EOF
}

cmd_install() {
  require_runtime

  # A prefix without the launcher is a failed/partial install — wipe it so the
  # installer starts from a clean state.
  if [[ -d $prefix && ! -e $launcher ]]; then
    echo "Removing incomplete Battle.net prefix at $prefix"
    rm -rf "$prefix"
  fi

  mkdir -p "$prefix"

  local setup
  setup="$(mktemp --suffix=.exe)"
  trap 'rm -f "$setup"' EXIT

  echo "Downloading Battle.net installer…"
  curl -fL -o "$setup" "$installer_url" || die "Failed to download the Battle.net installer."

  echo "Launching the installer through umu…"
  umu-run "$setup"
}

cmd_play() {
  require_runtime
  [[ -e $launcher ]] || die "Battle.net is not installed — run: omanix-gaming-battlenet install"
  umu-run "$launcher"
}

cmd_remove() {
  if [[ -d $prefix ]]; then
    rm -rf "$prefix"
    echo "Removed $prefix"
  else
    echo "Nothing to remove ($prefix does not exist)."
  fi
}

case "${1:-}" in
  install) cmd_install ;;
  play) cmd_play ;;
  remove) cmd_remove ;;
  -h | --help | "") usage ;;
  *) usage >&2; exit 1 ;;
esac
