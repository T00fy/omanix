#!/bin/bash

# omanix:summary=Send an IPC call to the running Omanix shell
# omanix:args=[-q] <target> <method> [args...]
# omanix:examples=omanix-shell shell ping | omanix-shell shell toggle omanix.menu '{"menu":"root"}'

QUIET=0
if [[ ${1:-} == "-q" ]]; then
  QUIET=1
  shift
fi

fail() {
  (( QUIET )) && exit 0
  echo "$1" >&2
  exit 1
}

if (( $# == 0 )) || [[ $1 == "-h" || $1 == "--help" ]]; then
  cat <<USAGE
Usage: omanix-shell [-q] <target> <method> [args...]

Forwards an IPC call to the running Omanix shell. The shell is expected
to already be running; this command does not start it.

Options:
  -q  Quiet best-effort mode. Suppress output and return success even when
      the shell, target, method, or arguments are unavailable.

Examples:
  omanix-shell shell ping
  omanix-shell -q omanix.indicators refresh
  omanix-shell shell listPlugins
  omanix-shell shell toggle omanix.menu '{"menu":"root"}'
USAGE
  exit 0
fi

(( $# >= 2 )) || fail "Usage: omanix-shell <target> <method> [args...]"
[[ -n ${OMANIX_PATH:-} ]] || fail "OMANIX_PATH is not set"
[[ -f $OMANIX_PATH/shell/shell.qml ]] || fail "omanix-shell config not found: $OMANIX_PATH/shell/shell.qml"

# qs matches instances by display, and a caller from outside the session (an
# ssh or TTY omanix-restart-shell, and the migrations it runs for) has none,
# so recover it from the compositor socket.
if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
  socket=$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$UID}"/wayland-[0-9]* 2>/dev/null | grep -v '\.lock$' | head -n1)
  [[ -n $socket ]] && export WAYLAND_DISPLAY=${socket##*/}
fi

if [[ $1 == "shell" && ( $2 == "summon" || $2 == "toggle" ) ]] && (( $# == 3 )); then
  set -- "$1" "$2" "$3" "{}"
fi

# The -- keeps function names that shadow qs subcommands (e.g. show) as
# positionals. qs reports connection failures with a nonzero exit, but IPC-level
# failures (unknown target/function, bad arguments) go to stdout with exit 0.
ipc_timeout=${OMANIX_SHELL_IPC_TIMEOUT:-2s}
output=$(timeout --kill-after=1s "$ipc_timeout" qs ipc -n -p "$OMANIX_PATH/shell" call -- "$@" 2>/dev/null)
ipc_status=$?

if (( ipc_status == 124 || ipc_status == 137 )); then
  fail "omanix-shell is not responding"
elif (( ipc_status != 0 )); then
  fail "omanix-shell is not running"
fi

case $output in
  "Target not found." | "Function not found." | "Too few arguments provided"* | "Too many arguments provided"*)
    fail "$output"
    ;;
  # A starting shell answers on stdout and exits 0, so a ping reads it as up
  # and the next call's answer as a result. It is as unreachable as none.
  "Not ready to accept queries yet"*)
    fail "omanix-shell is not ready"
    ;;
esac

if (( !QUIET )) && [[ -n $output ]]; then
  echo "$output"
fi
exit 0
