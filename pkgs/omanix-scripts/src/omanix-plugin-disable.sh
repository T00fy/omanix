#!/bin/bash

# omanix:summary=Disable a shell plugin
# omanix:args=<id>

set -euo pipefail

fail() {
  echo "omanix-plugin-disable: $*" >&2
  exit 1
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: omanix-plugin-disable <id>"
  exit 0
fi

id="${1:-}"
[[ -n $id ]] || fail "plugin id is required"

result=$(omanix-shell shell setPluginEnabled "$id" false)
[[ $result == "ok" ]] ||
  fail "plugin '$id' is not known; run: omanix-shell shell rescanPlugins"

echo "Disabled $id"
