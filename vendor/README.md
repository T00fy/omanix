# vendor/

Committed, hand-fork **snapshots** of upstream source that omanix owns (decision D1 in
`../PORTING-QUATTRO.md`). Nothing here is a live dependency: no fetch, no `flake = false`
input, no build-time patch. Reproducibility comes from these files being in git.

## Contents

- **`omanix-shell/`** — a faithful mirror of Omarchy's Quickshell `shell/` tree. Keep it a
  mirror: do not add omanix-authored files *inside* it (a re-vendor would clobber them and
  the diff would be noise). omanix-authored notes live here at the `vendor/` root instead.
- **`PROVENANCE.md`** — the pinned rev, commit SHA, vendored date, rename-ruleset reference,
  and the local-edit policy for each snapshot.

## State: RENAMED (Q0-03 ruleset applied)

`omanix-shell/` is the upstream tree with the omanix namespace rename applied
(`omarchy-*` → `omanix-*`, `$OMARCHY_PATH` → `$OMANIX_PATH`, `omarchy.*` IPC ids → `omanix.*`),
plus the D5 structural path rewrites (strip `$OMANIX_PATH/bin/` prefixes; repoint config/default
refs to in-store `$OMANIX_PATH/shell/{config,defaults}/…`). The ruleset lives in
`apply_rename()` in `../scripts/vendor-omarchy.sh`; see `PROVENANCE.md` for details. The only
retained `omarchy` literals are inside `http(s)://` URLs (an example plugin URL in `README.md`).

## Regenerate

Run the manual developer tool [`../scripts/vendor-omarchy.sh`](../scripts/vendor-omarchy.sh)
against a chosen upstream rev. It is **never** part of `nix build`. After running, update
`PROVENANCE.md` and review `git diff vendor/` before committing.
