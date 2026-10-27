# Contributing

## Commit messages

Omanix uses [Conventional Commits](https://www.conventionalcommits.org/).
[release-please](https://github.com/googleapis/release-please) reads them on
`main` to pick the next version and write `CHANGELOG.md`, so the type matters.

```
<type>(<scope>): <summary in imperative mood>

<optional body: why, not what>

<optional footer, e.g. BREAKING CHANGE: ...>
```

| Type | Use for | Release |
|---|---|---|
| `feat` | New user-visible capability (option, theme, app, keybind, script) | minor |
| `fix` | Bug fix, including breakage from upstream updates | patch |
| `perf` | Faster eval/build/runtime, no behaviour change | patch |
| `refactor` | Restructure with no behaviour change | none |
| `docs` | Docs and option descriptions only | none |
| `build` | Flake inputs, packaging, overlays | none |
| `ci` | GitHub workflows | none |
| `chore` | Anything else that users won't notice | none |
| `revert` | Reverting an earlier commit | patch |

A `commit-msg` hook rejects messages that don't match. Enable it once per
clone:

```bash
git config core.hooksPath .githooks
```

Scopes are optional; prefer the area of the repo that changed: `hyprland`,
`quickshell`, `theme`, `plugins`, `scripts`, `apps`, `terminal`, `languages`,
`nixos`, `sddm`, `vendor`, `flake`, `docs`.

Input bumps that fix or change something users will see should be `fix` or
`feat`, not `build` — otherwise they won't produce a release.

### Breaking changes

Downstream flakes pin Omanix by version, so a major bump has to mean "your
config may stop evaluating or behave differently". Mark a commit breaking with
`!` after the type/scope **and** a `BREAKING CHANGE:` footer explaining the
migration whenever it:

- renames, removes, or changes the type of an `omanix.*` option
- changes an option's default in a way users will notice
- removes a package, app, keybinding, script, or theme
- requires users to change their flake inputs or module imports

```
feat(quickshell)!: move bar options under omanix.quickshell.bar

BREAKING CHANGE: omanix.bar.* is now omanix.quickshell.bar.*. Rename the
attribute path in your config.
```

Use `lib.mkRenamedOptionModule` / `lib.mkRemovedOptionModule` where possible so
the break comes with a helpful evaluation error.

## Pull requests

PRs are squash-merged, so the **PR title** becomes the commit on `main` and
must follow the format above (CI enforces it). Keep one logical change per PR;
if a PR contains both a feature and an unrelated fix, split it.

`nix flake check` must pass.

## Releases

Nothing to do by hand. release-please keeps a "chore: release x.y.z" PR open
that accumulates the changelog; merging it tags `vX.Y.Z`, creates the GitHub
release, and publishes that version to FlakeHub. Don't create tags manually.
