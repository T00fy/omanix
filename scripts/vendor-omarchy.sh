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

# --- Q0-03 rename ruleset ----------------------------------------------------
# Deterministic, UTF-8-safe transform applied ONCE at vendor time over the extracted tree,
# in place. Output is committed; the build never runs this. Two classes of change (D1 + D5):
#
#   D1  Case-preserving namespace rename: omarchy->omanix, Omarchy->Omanix, OMARCHY->OMANIX.
#       A plain substring swap is safe here — recon found no mixed-case forms and no
#       coincidental substrings (the only omarchy{C,P} hits are omarchyConfigDir/omarchyPath,
#       which *should* rename). This one rule covers command names, $OMARCHY_PATH + all
#       OMARCHY_* env vars, the omarchyPath QML property, omarchy.* IPC/plugin ids, layer-shell
#       namespaces, PAM config names, notification protocol ids, and ~/.config|.local/state
#       runtime dirs. Decision (confirmed): rename EVERYTHING EXCEPT the literal word inside
#       http(s):// URLs (keeps the example plugin URL in README.md intact).
#
#   D5  Structural path rewrites (NOT substring) so the shell stops assuming an Omarchy
#       on-disk checkout:
#         §4a  strip the "$OMANIX_PATH/bin/" prefix off script calls -> bare omanix-* PATH names.
#         §4b  repoint the 3 out-of-tree config/default refs to in-store $OMANIX_PATH/shell/
#              subpaths (Phase-1 packaging installs the Nix-generated files there). This keeps
#              them inside shell/ (resolved like other in-tree assets), NOT as synthetic
#              config//default//bin/ siblings of shell/ (D5 §1).
#
# Idempotent: on an already-renamed tree every rule matches nothing, so a second run is a no-op.
apply_rename() {
  local tree="$1"

  # All files in the tree are UTF-8 text (qml/js/json/md/svg/sh/py/qmldir); no binaries to skip.
  find "$tree" -type f -print0 | xargs -0 --no-run-if-empty perl -CSD -i -pe '
    # (0) Protect the word inside http(s):// URLs before the rename (encode with a sentinel
    #     that contains no "omarchy" substring, restored verbatim after the rename).
    s{(https?://\S+)}{ my $u=$1;
        $u=~s/omarchy/\x01L\x01/g; $u=~s/Omarchy/\x01T\x01/g; $u=~s/OMARCHY/\x01U\x01/g; $u }ge;

    # (1) D1 case-preserving namespace rename.
    s/Omarchy/Omanix/g; s/OMARCHY/OMANIX/g; s/omarchy/omanix/g;

    # Restore the URL-protected tokens.
    s/\x01L\x01/omarchy/g; s/\x01T\x01/Omarchy/g; s/\x01U\x01/OMARCHY/g;

    # (2) D5 §4a: strip the $OMANIX_PATH/bin/ prefix -> bare omanix-* command on PATH.
    s{(?:[A-Za-z_][A-Za-z0-9_]*\.)?omanixPath \+ "/bin/}{"}g;

    # (3) D5 §4b: repoint out-of-tree config/default refs to in-store $OMANIX_PATH/shell/ subpaths.
    s{omanixPath \+ "/config/omanix/shell\.json"}{omanixPath + "/shell/config/shell.json"}g;
    s{omanixPath \+ "/default/omanix/omanix-menu\.jsonc"}{omanixPath + "/shell/defaults/omanix-menu.jsonc"}g;
    s{omanixPath \+ "/default/omanix/launcher\.hides"}{omanixPath + "/shell/defaults/launcher.hides"}g;
  '
}
# ----------------------------------------------------------------------------

echo ">> Applying Q0-03 rename ruleset (D1 namespace + D5 structural rewrites) ..."
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
