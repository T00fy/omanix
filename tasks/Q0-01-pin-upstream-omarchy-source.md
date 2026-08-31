# Q0-01: Pin upstream omarchy source & vendoring input

- **Phase:** 0
- **Status:** todo
- **Depends on:** none
- **Blocks:** Q0-02, Q0-03, Q1-01, Q1-02
- **Size:** S

## Context
Omanix must vendor parts of Omarchy 4.0.2 (the QML `shell/` tree, plugin assets, and several
`bin/` scripts) into the Nix store. To keep this reproducible and re-syncable, the omarchy
source must enter the flake as a **pinned, non-flake input** at a single known revision. Every
later vendoring ticket (Q1-02, and Phase 4/5 script ports) consumes this one input, so the
whole port tracks a single upstream rev that a human bumps deliberately.

This ticket only establishes the input and a documented bump procedure. It does not vendor
anything yet.

## Scope
**In scope:** add an `omarchy-src` flake input (`flake = false`) pinned to a tag/rev; expose it
to the overlay/packages; document the bump procedure.
**Out of scope:** actually building `omanix-shell` (Q1-02), the rename patch (Q0-03), any
runtime wiring.

## Implementation notes
- Edit `flake.nix` `inputs`, following the existing `yt-dlp-src` pattern (a `flake = false`
  source input):
  ```nix
  # Upstream Omarchy source, vendored into the store (shell QML, assets, scripts).
  # Pinned deliberately; bump via the procedure in tasks/Q0-01-*.md. Not a flake.
  omarchy-src = {
    url = "github:omacom/omarchy/<PIN>";   # <PIN> = TBD, see below
    flake = false;
  };
  ```
- **`<PIN>` is TBD — the human must fill it.** Leave the literal placeholder `REPLACE_ME` in
  `flake.nix` with a `# TODO(Q0-01):` comment, or set it to `v4.0.2` if that tag resolves on
  the upstream remote. Confirm the intended upstream repo owner (`omacom/omarchy`) with the
  maintainer before pinning — the local reference checkout at `/home/toofy/projects/omarchy`
  is on branch/tag `v4.0.2`.
- Thread `inputs.omarchy-src` through to where packages are called. The overlay in `flake.nix`
  currently calls `./pkgs/*`; pass the source via `callPackage`'s args or `specialArgs`, e.g.
  `omanix-shell = final.callPackage ./pkgs/omanix-shell { omarchySrc = inputs.omarchy-src; };`
  (the package is created in Q1-02; here just make the plumbing available).
- Record the resolved rev in `flake.lock` (automatic on `nix flake lock`).
- Document the bump procedure in this ticket's "Bump procedure" note and in
  `../PORTING-QUATTRO.md` Phase 0 (fill the "source rev" blank).

### Bump procedure (document, don't run)
1. `nix flake lock --update-input omarchy-src` (or set a new tag in `flake.nix`).
2. Rebuild `omanix-shell`; review the Q0-03 rename patch diff for new false positives.
3. Runtime-check the shell (Q1-03 acceptance).

## Acceptance criteria
- [ ] `flake.nix` has an `omarchy-src` input with `flake = false`.
- [ ] The pin is either a real resolvable rev/tag or a clearly-marked `TODO(Q0-01)` placeholder the human must set.
- [ ] The input is reachable by `pkgs/` derivations (plumbing in place, even if no package consumes it yet).
- [ ] `nix flake metadata` lists `omarchy-src`; `flake.lock` records it (once a real pin is set).
- [ ] Bump procedure is documented (this ticket + `../PORTING-QUATTRO.md` Phase 0 blank filled or noted as pending pin).

## Testing
```bash
cd /home/toofy/projects/omanix
nix flake metadata            # omarchy-src appears in inputs
nix flake check               # still evaluates (no consumer yet, so must not regress)
```
If a real pin is set: `nix flake lock` succeeds and `flake.lock` gains the `omarchy-src` node.

## References
- omarchy: repo root at `/home/toofy/projects/omarchy` (tag `v4.0.2`)
- omanix: `flake.nix` (inputs, `yt-dlp-src` pattern at lines ~37-40; overlay ~70-81)
