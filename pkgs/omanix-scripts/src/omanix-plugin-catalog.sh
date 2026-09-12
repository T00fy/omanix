#!/bin/bash

# omanix:summary=Emit every first-party and user plugin manifest as JSON

# Walks $OMANIX_PATH/shell/plugins and ~/.config/omanix/plugins, reads every
# manifest.json / *.manifest.json, and emits one JSON object per plugin with
# computed fields (sourceDir, barWidgetPath, barPath, firstParty). This is the
# single source of truth used by plugin enable/clone, so those commands never
# re-implement manifest walking. Needs no running shell (pure disk walk).

set -o pipefail

[[ -n ${OMANIX_PATH:-} ]] || {
  echo "omanix-plugin-catalog: OMANIX_PATH is not set" >&2
  exit 1
}

paths=()

while IFS= read -r manifest; do
  paths+=("$manifest")
done < <(find "$OMANIX_PATH/shell/plugins" -mindepth 2 -maxdepth 4 -type f \( -name manifest.json -o -name '*.manifest.json' \) 2>/dev/null | sort)

user_dir="$HOME/.config/omanix/plugins"
if [[ -d $user_dir ]]; then
  while IFS= read -r manifest; do
    paths+=("$manifest")
  done < <(find -L "$user_dir" -mindepth 2 -maxdepth 2 -type f -name manifest.json \
    ! -path "$user_dir/.*/*" 2>/dev/null | sort)
fi

if (( ${#paths[@]} == 0 )); then
  echo "[]"
  exit 0
fi

jq -n '
  [ inputs
    | . as $manifest
    | input_filename as $manifestPath
    | ($manifestPath | sub("/manifest.json$"; "") | sub("/[^/]+\\.manifest\\.json$"; "")) as $sourceDir
    | {
        id: ($manifest.id // ""),
        name: ($manifest.name // $manifest.id // ""),
        description: ($manifest.description // ""),
        kinds: ($manifest.kinds // []),
        firstParty: (($manifest.id // "") | startswith("omanix.")),
        manifestPath: $manifestPath,
        sourceDir: $sourceDir,
        entryPoints: ($manifest.entryPoints // {}),
        barWidget: ($manifest.barWidget // null),
        bar: ($manifest.bar // null)
      }
    | .barWidgetPath = (
        if (.entryPoints.barWidget // null) != null
        then (.sourceDir + "/" + .entryPoints.barWidget)
        else null end)
    | .barPath = (
        if (.entryPoints.bar // null) != null
        then (.sourceDir + "/" + .entryPoints.bar)
        else null end)
    | select(.id != "")
  ]
  | unique_by(.id)
' "${paths[@]}"
