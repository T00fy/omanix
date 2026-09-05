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

## State: RAW (not yet renamed)

`omanix-shell/` is currently the **unmodified** upstream tree. The omanix namespace rename
(`omarchy-*` → `omanix-*`, `$OMARCHY_PATH` → `$OMANIX_PATH`, `omarchy.*` IPC ids → `omanix.*`)
is defined and applied by **Q0-03**, not here (Q0-01).

## Regenerate

Run the manual developer tool [`../scripts/vendor-omarchy.sh`](../scripts/vendor-omarchy.sh)
against a chosen upstream rev. It is **never** part of `nix build`. After running, update
`PROVENANCE.md` and review `git diff vendor/` before committing.
