#!/usr/bin/env bash
#
# vendor-omarchy.sh — regenerate the vendored Omarchy shell snapshot.
#
# MANUAL DEVELOPER TOOL. This is NEVER part of `nix build`. omanix vendors a committed,
# hand-fork snapshot of Omarchy's Quickshell `shell/` tree (decision D1 in PORTING-QUATTRO.md);
# the build consumes the committed files under vendor/omanix-shell/. Re-syncing a newer upstream
# is a rare, deliberate act: run this script against a rev, then review `git diff vendor/`.
#
# What it does:
#   1. Clones omacom/omarchy at the given rev into a temp dir.
#   2. Applies the omanix namespace rename over the extracted `shell/` (Q0-03 ruleset).
#      NOTE: in Q0-01 the rename is a documented NO-OP placeholder — Q0-03 fills apply_rename() in.
#   3. Copies `shell/` into vendor/omanix-shell/.
#   4. Prints a `git diff --stat` summary vs what's committed.
#
# Usage:
#   scripts/vendor-omarchy.sh [rev]
#     rev   upstream git rev/tag/branch to vendor (default: v4.0.2, the currently pinned rev).
#
# Env:
#   OMARCHY_REMOTE   git URL or local path to clone from
#                    (default: https://github.com/omacom/omarchy.git;
#                     set to a local checkout, e.g. ~/projects/omarchy, to work offline).
#
# After running, update vendor/PROVENANCE.md (rev, SHA, date) and review the diff before committing.

set -euo pipefail

REV="${1:-v4.0.2}"
OMARCHY_REMOTE="${OMARCHY_REMOTE:-https://github.com/omacom/omarchy.git}"

# Repo root = parent of this script's dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="$REPO_ROOT/vendor/omanix-shell"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo ">> Cloning $OMARCHY_REMOTE @ $REV ..."
git clone --quiet --filter=blob:none --no-checkout "$OMARCHY_REMOTE" "$TMP/omarchy"
git -C "$TMP/omarchy" checkout --quiet "$REV"

SRC="$TMP/omarchy/shell"
if [[ ! -d "$SRC" ]]; then
  echo "!! No shell/ subtree at rev $REV" >&2
  exit 1
fi

# --- Q0-03 rename hook -------------------------------------------------------
# Applies the D1 omanix namespace rename (omarchy-* -> omanix-*, $OMARCHY_PATH -> $OMANIX_PATH,
# omarchy.* IPC ids -> omanix.*, etc.) over the extracted tree, in place.
# Q0-01: intentionally a NO-OP so the committed snapshot is the RAW upstream tree.
# Q0-03: replace the body with the deterministic, UTF-8-safe rename ruleset.
apply_rename() {
  local tree="$1"
  : # no-op (Q0-03 fills this in)
}
# ----------------------------------------------------------------------------

echo ">> Applying rename ruleset (Q0-03; no-op in Q0-01) ..."
apply_rename "$SRC"

echo ">> Copying shell/ -> vendor/omanix-shell/ ..."
rm -rf "$DEST"
mkdir -p "$DEST"
# Copy tree contents (source only; no upstream VCS metadata is present in $SRC).
cp -a "$SRC/." "$DEST/"

echo ">> Diff vs committed (git diff --stat):"
git -C "$REPO_ROOT" add -A -- vendor/omanix-shell >/dev/null 2>&1 || true
git -C "$REPO_ROOT" diff --cached --stat -- vendor/omanix-shell || true
git -C "$REPO_ROOT" reset --quiet -- vendor/omanix-shell >/dev/null 2>&1 || true

echo ">> Done. Update vendor/PROVENANCE.md and review 'git diff vendor/' before committing."
