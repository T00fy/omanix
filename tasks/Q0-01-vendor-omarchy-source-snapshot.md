# Q0-01: Vendor upstream omarchy source into the repo (pinned snapshot)

- **Phase:** 0
- **Status:** todo
- **Depends on:** none
- **Blocks:** Q0-02, Q0-03, Q1-01, Q1-02
- **Size:** S

## Context
omanix reuses parts of Omarchy 4.0.2 — the Quickshell `shell/` QML tree and its assets, plus a few
`bin/` scripts studied for hand-ports. **Decided:** omanix does *not* track upstream as a live
dependency. Instead it takes a **one-time snapshot** — the needed source is copied into the omanix
repo, renamed to the omanix namespace (D1, Q0-03), and committed. This is a deliberate hard-fork
snapshot: omanix **owns** the vendored code, edits it directly, and does not re-sync on every build.

"Pinned" here means two things: the snapshot **records the exact upstream rev** it came from
(provenance), and the build is **reproducible because the files live in git** — no fetch, no flake
input, no dependency on the omarchy repo staying available. Re-vendoring a newer omarchy later is
possible but a rare, manual, deliberate act (re-run the vendor script + review), not something the
build does.

This ticket establishes where the vendored tree lives, the (re-runnable) vendoring procedure, and
the provenance record, and **removes the omarchy source flake input**. It does not build the
package (Q1-02) or hold the rename rules (Q0-03) or decide runtime plugin scope (Q0-05).

## Scope
**In scope:** pick the upstream rev; create the in-repo `vendor/` location; copy the upstream
`shell/` subtree + assets in; a `scripts/vendor-omarchy.sh` helper that regenerates the snapshot
(clone-at-rev → apply Q0-03 rename → copy subtree into `vendor/`); a `vendor/PROVENANCE.md` record;
commit the vendored tree; ensure no omarchy source flake input exists.
**Out of scope:** any `flake = false` omarchy input (explicitly removed vs the earlier plan); the
package build (Q1-02); the rename rule set (Q0-03, which the script calls); runtime plugin scope
(Q0-05).

## Implementation notes
- **No omarchy source flake input.** An earlier draft of this plan pinned a `flake = false`
  `omarchy-src` input fetched at build and threaded via `callPackage`/`specialArgs`. That approach
  is dropped. If any such stub was added to `flake.nix`, remove it and its plumbing. (Quickshell
  itself is unaffected — it remains a normal packaged dependency, Q1-01.)
- **Vendor location:** commit the tree under `vendor/omanix-shell/` mirroring upstream `shell/`
  layout, plus its assets. Keep it clearly separated from omanix-authored code so provenance is
  obvious. Add a short header/README stating it is vendored + renamed from omarchy and pointing at
  `PROVENANCE.md`.
- **Local-edit policy (pick and document):** since omanix owns the copy, hand-edits to the vendored
  tree are allowed. Recommended policy: prefer keeping local changes small and noting them in
  `PROVENANCE.md` (or as a `vendor/patches/` set) so a future re-vendor can reason about what to
  re-apply — but this is a convenience, not a hard rule. State the chosen policy.
- **Re-vendor script `scripts/vendor-omarchy.sh`:** a **developer tool run by hand**, never part of
  `nix build`. It clones `omacom/omarchy` at a given rev into a temp dir, runs the Q0-03 rename over
  it, copies the `shell/` subtree (+ assets) into `vendor/omanix-shell/`, and prints a diff summary
  vs what's committed. This is the "bump procedure" equivalent — a deliberate future re-sync is just
  re-running it against a newer rev and reviewing.
- **Provenance:** `vendor/PROVENANCE.md` records: upstream repo (`omacom/omarchy`), the exact
  rev/tag (confirm with the maintainer; the local reference checkout at `/home/toofy/projects/omarchy`
  is on `v4.0.2`), the **absolute date** vendored, the rename ruleset reference (Q0-03), and the
  subtree/assets copied.
- No `flake.lock` entry is needed for the source — reproducibility comes from the committed files.

## Acceptance criteria
- [ ] No omarchy source input in `flake.nix` (any earlier `omarchy-src` stub and its plumbing removed).
- [ ] A committed `vendor/omanix-shell/` tree holds the omarchy `shell/` source (+ assets) omanix needs.
- [ ] `scripts/vendor-omarchy.sh` regenerates that tree from a given upstream rev (clone → rename via Q0-03 → copy), documented as a manual dev tool, not a build step.
- [ ] `vendor/PROVENANCE.md` records repo, exact rev, absolute date, rename ruleset, and copied subtree/assets.
- [ ] The chosen local-edit policy is documented.
- [ ] `nix flake check` passes with no omarchy source input.

## Testing
```bash
cd /home/toofy/projects/omanix
nix flake metadata            # omarchy source is NOT listed among inputs
nix flake check               # evaluates without the removed input
ls vendor/omanix-shell/shell.qml   # the committed (renamed) tree is present
```
- Re-run `scripts/vendor-omarchy.sh` against the recorded rev → the regenerated tree matches what's committed (idempotent snapshot), or prints a reviewable diff if upstream moved.

## References
- omarchy: repo `omacom/omarchy` (rev per `PROVENANCE.md`); local reference checkout `/home/toofy/projects/omarchy` (`v4.0.2`); source subtree `shell/`
- omanix: new `vendor/omanix-shell/`, `scripts/vendor-omarchy.sh`, `vendor/PROVENANCE.md`; `flake.nix` (remove any omarchy source input); rename rules (Q0-03); consumed by `pkgs/omanix-shell/` (Q1-02)
