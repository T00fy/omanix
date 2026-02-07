#!/usr/bin/env bash
# Switch/move workspaces relative to the currently focused monitor.
# OMANIX_MONITOR_MAP is a colon-separated list of "name=base" pairs injected by the Nix wrapper.
# e.g. "DP-2=0:HDMI-A-2=10"

WORKSPACE_NUM="$1"
ACTION="${2:-switch}"  # switch, move, or movesilent

FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

# Parse monitor map to find the base for the focused monitor
BASE=0
IFS=':' read -ra ENTRIES <<< "$OMANIX_MONITOR_MAP"
for entry in "${ENTRIES[@]}"; do
  MON_NAME="${entry%%=*}"
  MON_BASE="${entry#*=}"
  if [[ "$MON_NAME" == "$FOCUSED_MONITOR" ]]; then
    BASE="$MON_BASE"
    break
  fi
done

TARGET_WORKSPACE=$((BASE + WORKSPACE_NUM))

case "$ACTION" in
  switch)
    hyprctl dispatch workspace "$TARGET_WORKSPACE"
    ;;
  move)
    hyprctl dispatch movetoworkspace "$TARGET_WORKSPACE"
    ;;
  movesilent)
    hyprctl dispatch movetoworkspacesilent "$TARGET_WORKSPACE"
    ;;
esac
