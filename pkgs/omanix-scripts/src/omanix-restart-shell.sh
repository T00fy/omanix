#!/bin/bash

# Restart the Omanix shell.

# A caller opened after dev link/unlink may disagree with the still-running
# desktop. The user manager receives Hyprland's environment at session start.
session_omanix_path=$(systemctl --user show-environment 2>/dev/null | sed -n 's/^OMANIX_PATH=//p' | tail -n 1)
: "${session_omanix_path:=$OMANIX_PATH}"

CONFIG_DIR="$session_omanix_path/shell"
[[ -f $CONFIG_DIR/shell.qml ]] || { echo "Omanix shell config not found: $CONFIG_DIR" >&2; exit 1; }

# Allow running from outside the session (e.g. over ssh) by deriving the
# Hyprland instance signature from the newest instance runtime dir.
if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hypr_dir=$(find "${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)
  [[ -n $hypr_dir ]] && export HYPRLAND_INSTANCE_SIGNATURE=${hypr_dir##*/}
fi

# Restarting a live lock client would kill the lock screen and strand the
# session behind Hyprland's failsafe. But a LOCK session without an active
# locker — the shell died, or its crash handler re-execed a fresh instance
# that holds no lock — sits in that failsafe with no way to authenticate,
# and a restart plus re-lock is the only way back in without a reboot. So
# ask the lock service rather than merely pinging the shell: only a locker
# that reports the lock secure or in progress is worth preserving.
relock=0
if omanix-hyprland-session-locked; then
  locking=$(OMANIX_PATH="$session_omanix_path" OMANIX_SHELL_IPC_TIMEOUT=0.5s omanix-shell lock status 2>/dev/null |
    jq -r '.secure or .requested' 2>/dev/null)
  if [[ $locking == "true" ]]; then
    echo "Refusing to restart Omanix shell while the session is locked." >&2
    exit 1
  fi
  relock=1
fi

# The lock plugin loads asynchronously, so a fresh shell answers ping before
# it can lock, and may even refuse early lock requests while its plugins or
# PAM config are still loading. Request the lock and poll until the session
# reports secure, re-requesting as needed, so recovery never claims success
# while the failsafe is still up. The deadline is generous because slow plugin
# discovery delays the lock IPC target.
relock_session() {
  local state deadline=$((SECONDS + 30))

  while (( SECONDS < deadline )); do
    state=$(OMANIX_PATH="$session_omanix_path" OMANIX_SHELL_IPC_TIMEOUT=0.5s omanix-shell lock status 2>/dev/null |
      jq -r 'if .secure == true then "secure" elif .requested == true then "locking" else "idle" end' 2>/dev/null)

    case $state in
      secure) return 0 ;;
      locking) ;;
      *) OMANIX_PATH="$session_omanix_path" OMANIX_SHELL_IPC_TIMEOUT=0.5s omanix-shell lock lock >/dev/null 2>&1 ;;
    esac

    sleep 0.1
  done

  return 1
}

# Each kill stops the oldest matching instance and only returns once it has
# fully exited, so the no-duplicate launch below can't race a dying shell.
while timeout 5 quickshell kill -p "$CONFIG_DIR" --any-display >/dev/null 2>&1; do :; done

# Spawn from Hyprland so the shell inherits the canonical session environment,
# not transient variables from a terminal, SSH connection, or development tool.
# Mirrors the Hyprland autostart launch command.
hyprctl dispatch exec "quickshell -n -p $session_omanix_path/shell" >/dev/null

for (( attempt = 0; attempt < 20; attempt++ )); do
  if OMANIX_PATH="$session_omanix_path" OMANIX_SHELL_IPC_TIMEOUT=0.5s omanix-shell shell ping >/dev/null 2>&1; then
    # The session stays compositor-locked after the old lock client died, so
    # re-acquire the lock and let the user authenticate out of it.
    if (( relock )) && ! relock_session; then
      echo "Omanix shell restarted, but the session lock was not re-secured." >&2
      exit 1
    fi
    exit 0
  fi
  sleep 0.1
done

echo "Omanix shell did not become ready after restart." >&2
exit 1
