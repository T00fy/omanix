# Q4-06: Security — sshd + sudoless-docker → Nix module options

- **Phase:** 4
- **Status:** todo
- **Depends on:** none
- **Blocks:** none
- **Size:** M

## Context
Omarchy 4.0.2 added interactive security setup: `omarchy-setup-security-sshd` (install/enable
OpenSSH, open a rate-limited firewall port, authorize a key from GitHub/paste/file, then disable
password auth *only after* a key is authorized, validated with `sshd -t`/`sshd -T`) and
`omarchy-setup-security-sudoless-docker` (add user to `docker` group with a root-equivalent
warning; default posture keeps Docker behind a polkit/sudo prompt via `omarchy-sudo-docker`).

These are imperative wizards that mutate `/etc` on Arch. On NixOS the **intent is declarative** —
port the *policy*, not the scripts. Omanix already has `modules/nixos/docker.nix`.

## Scope
**In scope:** express the sshd hardening and Docker posture as NixOS module options under
`omanix.security.*`, wiring `services.openssh`, the firewall, and `users.groups`/PAM. Provide the
GitHub-key-import convenience declaratively (fetch/pin authorized keys).
**Out of scope:** porting the interactive gum wizards verbatim; UFW (NixOS uses
`networking.firewall`/nftables — do not port `ufw`).

## Implementation notes
- **sshd** → new `modules/nixos/security-sshd.nix` (or a section in the main module) exposing e.g.:
  - `omanix.security.sshd.enable` → `services.openssh.enable = true`.
  - `omanix.security.sshd.authorizedKeys` (list of strings) and/or
    `omanix.security.sshd.githubKeys` (list of GitHub usernames) → resolve to
    `users.users.<u>.openssh.authorizedKeys.keys`. For GitHub keys, prefer a **pinned** fetch
    (e.g. a fetched `https://github.com/<user>.keys` with a hash, or documented as
    build-input) rather than a runtime curl — keep it reproducible (D-philosophy).
  - When at least one key is present, set hardening:
    `services.openssh.settings.PasswordAuthentication = false;`
    `services.openssh.settings.KbdInteractiveAuthentication = false;`. **Guard**: refuse to
    disable password auth if no key is configured (assertion) — this mirrors omarchy's
    "only after a key is authorized" safety and prevents lockout.
  - Rate-limit: `networking.firewall.allowedTCPPorts = [ 22 ]` plus (optional) an nftables limit
    rule; document that NixOS's default firewall replaces `ufw limit`.
- **sudoless-docker** → extend `modules/nixos/docker.nix`:
  - `omanix.security.sudolessDocker.enable` (default **false**) → adds the primary user to the
    `docker` group, with the root-equivalence caveat in the option `description`.
  - Default posture (option false): Docker stays privileged; port `omarchy-sudo-docker` as a
    small wrapper script (polkit/`sudo`-gated `docker`) for users who don't opt into sudoless.
    Follow omanix/omarchy privilege-escalation conventions (terminal → sudo, no terminal → pkexec).
- Add an assertion test proving the anti-lockout guard.

## Acceptance criteria
- [ ] `omanix.security.sshd.{enable,authorizedKeys,githubKeys}` options exist and configure `services.openssh` + firewall.
- [ ] Enabling sshd with **no** key configured triggers a build-time assertion (no silent password-auth disable).
- [ ] With a key configured, evaluated config has `PasswordAuthentication = false` and `KbdInteractiveAuthentication = false` and the key in the user's authorized keys.
- [ ] GitHub-key import is reproducible (pinned), not a runtime curl.
- [ ] `omanix.security.sudolessDocker.enable` (default false) gates docker-group membership; the option description states the root-equivalence risk.
- [ ] `omanix-sudo-docker` wrapper ported (D1) for the default (non-sudoless) posture.
- [ ] The generated options doc builds with the new options.

## Testing
- `nix flake check` passes (including the new assertion module).
- Eval test: a config enabling sshd with a key → assert the three settings resolve as above (`nix eval` on the built config, or a NixOS `assertions`/test).
- Eval test: enabling sshd with no key → `nix flake check`/build **fails** with the guard message.
- Eval test: `sudolessDocker.enable = true` → user is in `config.users.users.<u>.extraGroups` containing `docker`; false → not present.
- `nix build .#docs` (options reference) succeeds.

## References
- omarchy: `bin/omarchy-setup-security-sshd`, `bin/omarchy-remove-security-sshd`, `bin/omarchy-setup-security-sudoless-docker`, `bin/omarchy-remove-security-sudoless-docker`, `bin/omarchy-sudo-docker`
- omanix: `modules/nixos/docker.nix`, `modules/nixos/default.nix`, `docs/generate-options.nix`
