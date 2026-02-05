#!/usr/bin/env bash
# Toggles window gaps on the active workspace between no gaps and defaults.

workspace_id=$(hyprctl activeworkspace -j | jq -r .id)
gaps=$(hyprctl workspacerules -j | jq -r ".[] | select(.workspaceString==\"$workspace_id\") | .gapsOut[0] // 0")

if [[ $gaps == "0" ]]; then
  hyprctl keyword "workspace $workspace_id, gapsout:${OMANIX_GAPS_OUTER:-10}, gapsin:${OMANIX_GAPS_INNER:-5}, bordersize:${OMANIX_BORDER_SIZE:-2}"
else
  hyprctl keyword "workspace $workspace_id, gapsout:0, gapsin:0, bordersize:0"
fi
