#!/bin/bash

# omanix:summary=Manage the speaker tuning for this laptop
# omanix:args=<on|off|status|match|fronted-sink> [--force]
# omanix:examples=omanix-audio-tuning status | omanix-audio-tuning on | omanix-audio-tuning off

set -uo pipefail

# The tuning data ships read-only in the Nix store; OMANIX_AUDIO_TUNINGS is
# injected by the scripts package (pkgs/omanix-audio-tunings).
tunings_dir="${OMANIX_AUDIO_TUNINGS:-}/tunings"
host_source="${OMANIX_AUDIO_TUNINGS:-}/filter-chain-host.conf"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

# The tuning is hosted by its own PipeWire client, under its own config name, so
# switching it needs no audio restart -- a restart drops every PulseAudio client's
# connection, and applications that do not reconnect (Spotify) then have to be
# restarted by hand. The name is deliberately not PipeWire's stock
# filter-chain.conf, which merges every fragment in filter-chain.conf.d/ and would
# make this service host unrelated user filters too. The systemd unit itself is
# declared by Nix (omanix.audio.speakerTuning.enable) -- this script only renders
# the runtime config the unit's `pipewire -c` reads, and starts/stops the unit.
host_config_name=omanix-speaker-tuning.conf
host_config="$config_home/pipewire/$host_config_name"
fragment="$config_home/pipewire/$host_config_name.d/90-tuning.conf"
unit_name=omanix-speaker-tuning.service

sink_name=omanix_speaker_tuning

action="${1:-status}"
force=0
[[ ${2:-} == "--force" ]] && force=1

unit_declared() {
  systemctl --user cat "$unit_name" >/dev/null 2>&1
}

sink_matching() {
  pactl list sinks short 2>/dev/null | awk -v p="$1" '$2 ~ p {print $2; exit}'
}

# Dell keys its Cirrus speaker firmware on the DMI product SKU, which makes it the
# most precise identifier available for these machines -- narrower than a product
# name, and it distinguishes models whose names differ only by marketing. Compared
# case-insensitively against an exact SKU, never a substring.
sku_matches() {
  local sku want
  sku="$(cat /sys/class/dmi/id/product_sku 2>/dev/null)"
  [[ -n $sku ]] || return 1
  for want in "$@"; do
    [[ ${sku,,} == "${want,,}" ]] && return 0
  done
  return 1
}

# omanix-hw-match is optional (a future hardware helper); a tuning that keys on
# DMI simply never matches until it ships, rather than erroring here.
dmi_matches() {
  local want
  command -v omanix-hw-match >/dev/null 2>&1 || return 1
  for want in "$@"; do
    omanix-hw-match "$want" 2>/dev/null && return 0
  done
  return 1
}

# Print the tuning directory matching this laptop, if any. Matching is data, not
# code: a tuning declares the DMI/SKU it belongs to and the sink it expects, so
# most tunings can be added as a directory with no new script.
tuning_match() {
  local dir
  [[ -d $tunings_dir ]] || return 1
  for dir in "$tunings_dir"/*/; do
    [[ -r $dir/tuning.conf ]] || continue

    unset match_dmi match_sku match_command sink_pattern
    # shellcheck disable=SC1090
    source "$dir/tuning.conf"

    if [[ -n ${match_command:-} ]]; then
      "$match_command" 2>/dev/null || continue
    elif [[ -n ${match_sku:-} ]]; then
      sku_matches "${match_sku[@]}" || continue
    elif [[ -n ${match_dmi:-} ]]; then
      dmi_matches "${match_dmi[@]}" || continue
    else
      continue
    fi

    # Required whichever way the tuning matched: the graph's target sink is
    # substituted from it, so a tuning without one cannot be installed.
    [[ -n ${sink_pattern:-} ]] || continue

    printf '%s\n' "${dir%/}"
    return 0
  done
  return 1
}

# The physical sink the matched tuning is built for, from the tuning's own
# sink_pattern rather than a hard-coded regex.
tuned_hardware_sink() {
  local dir found
  dir="$(tuning_match)" || return 1
  unset sink_pattern
  # shellcheck disable=SC1090
  source "$dir/tuning.conf"
  [[ -n ${sink_pattern:-} ]] || return 1
  found="$(sink_matching "$sink_pattern")"
  [[ -n $found ]] || return 1
  printf '%s\n' "$found"
}

tuning_present() {
  pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -x "$sink_name" >/dev/null
}

# Only real application streams may be moved. A filter-chain's own output is also
# a sink input but carries no application.name, and moving it would rewire the
# tuning itself.
app_streams() {
  pactl list sink-inputs 2>/dev/null | awk '
    /^Sink Input #/ {id = substr($3, 2)}
    /application\.name = / {
      app = $0
      sub(/.*application\.name = "/, "", app)
      sub(/"$/, "", app)
      if (app != "EasyEffects") print id
    }'
}

move_apps_to() {
  local target="$1" id
  for id in $(app_streams); do
    pactl move-sink-input "$id" "$target" 2>/dev/null || true
  done
}

# WirePlumber can link the output elsewhere if the target is missing when the host
# starts. node.dont-fallback guards against it, but verify rather than assume.
tuning_downstream_sink() {
  omanix-audio-output-sink "$sink_name" 2>/dev/null
}

easyeffects_running() {
  pactl list sinks short 2>/dev/null | awk '{print $2}' | grep -x easyeffects_sink >/dev/null ||
    pgrep -u "$(id -u)" -x easyeffects >/dev/null 2>&1 ||
    systemctl --user is-active --quiet easyeffects.service 2>/dev/null
}

case "$action" in
  match)
    tuning_match
    ;;

  fronted-sink)
    # The tuning is a virtual sink in front of the real speakers, so both exist
    # in the graph. Selecting the physical one would only bypass the tuning, so
    # callers keep it out of the output list while the tuning is up.
    tuning_present || exit 1
    tuned_hardware_sink
    ;;

  status)
    if ! unit_declared; then
      echo "Speaker tuning: not enabled (set omanix.audio.speakerTuning.enable = true)"
      exit 0
    fi
    if [[ -r $fragment ]]; then
      echo "Rendered:     yes ($fragment)"
    else
      echo "Rendered:     no"
    fi
    host_state="$(systemctl --user is-active "$unit_name" 2>/dev/null)"
    echo "Host service: ${host_state:-inactive}"
    if tuning_present; then
      echo "Tuning sink:  present"
    else
      echo "Tuning sink:  absent"
    fi
    echo "Default sink: $(pactl get-default-sink 2>/dev/null)"
    if dir="$(tuning_match)"; then
      unset description
      # shellcheck disable=SC1090
      source "$dir/tuning.conf"
      echo "Matches:      ${description:-?} ($(basename "$dir"))"
    else
      echo "Matches:      nothing ships for this laptop"
    fi
    ;;

  off)
    if [[ ! -r $fragment ]] && ! systemctl --user is-active --quiet "$unit_name" 2>/dev/null; then
      echo "No speaker tuning installed."
      exit 0
    fi

    speakers="$(tuned_hardware_sink)" || speakers=""

    systemctl --user stop "$unit_name" >/dev/null 2>&1
    rm -f "$fragment" "$host_config"
    rmdir "$config_home/pipewire/$host_config_name.d" 2>/dev/null

    for _ in {1..20}; do
      tuning_present || break
      sleep 0.25
    done

    if [[ -n $speakers ]]; then
      pactl set-default-sink "$speakers" >/dev/null 2>&1
      # Streams left on the vanished tuning sink reconnect wherever PipeWire puts
      # them, which is not necessarily the speakers.
      move_apps_to "$speakers"
    fi
    echo "Speaker tuning removed."
    ;;

  on)
    unit_declared || {
      echo "Speaker tuning is not enabled. Set omanix.audio.speakerTuning.enable = true" >&2
      echo "and rebuild, then run: omanix-audio-tuning on" >&2
      exit 1
    }

    [[ -d $tunings_dir ]] || {
      echo "No tunings shipped at $tunings_dir" >&2
      exit 1
    }

    selected="$(tuning_match)" || {
      echo "No speaker tuning matches this laptop."
      exit 0
    }

    unset description sink_pattern
    # shellcheck disable=SC1090
    source "$selected/tuning.conf"

    # At first-run the session is up but the sink can still be settling.
    for _ in {1..20}; do
      speaker_sink="$(sink_matching "$sink_pattern")"
      [[ -n $speaker_sink ]] && break
      sleep 0.5
    done
    [[ -n ${speaker_sink:-} ]] || {
      echo "A tuning applies to this laptop but no sink matching $sink_pattern" >&2
      echo "is present. Re-run after the audio server is up:" >&2
      echo "  omanix-audio-tuning on" >&2
      exit 1
    }

    if easyeffects_running; then
      cat >&2 <<'EOF'
EasyEffects is running. It moves any stream that follows the default sink to its
own sink, so a tuning installed now would be bypassed.

Stop it first:  systemctl --user disable --now easyeffects.service
EOF
      exit 1
    fi

    # Every tuning ends in a limiter, which is an LV2 plugin. Without it the graph
    # fails to instantiate and the tuning sink never appears. OMANIX_AUDIO_LV2_PATH
    # is injected by the scripts package when the subsystem is enabled.
    if [[ -n ${OMANIX_AUDIO_LV2_PATH:-} ]] &&
      [[ ! -e $OMANIX_AUDIO_LV2_PATH/lsp-plugins.lv2/limiter_stereo.ttl ]]; then
      echo "lsp-plugins-lv2 is required for the tuning limiter but was not found" >&2
      echo "under $OMANIX_AUDIO_LV2_PATH." >&2
      exit 1
    fi

    rendered="$(mktemp)"
    trap 'rm -f "$rendered"' EXIT
    sed "s|@SPEAKER_SINK@|$speaker_sink|g" "$selected/filter-chain.conf" >"$rendered"

    if ((!force)) && [[ -r $fragment ]] && cmp -s "$rendered" "$fragment" &&
      [[ -r $host_config ]] && cmp -s "$host_source" "$host_config" &&
      systemctl --user is-active --quiet "$unit_name" 2>/dev/null &&
      [[ "$(tuning_downstream_sink)" == "$speaker_sink" ]]; then
      echo "Speaker tuning already current: $description"
      exit 0
    fi

    install -Dm644 "$host_source" "$host_config"
    install -Dm644 "$rendered" "$fragment"
    systemctl --user restart "$unit_name" >/dev/null 2>&1
    echo "Installed speaker tuning: $description"

    for _ in {1..40}; do
      tuning_present && break
      sleep 0.25
    done
    if ! tuning_present; then
      systemctl --user stop "$unit_name" >/dev/null 2>&1
      rm -f "$fragment" "$host_config"
      echo "Tuning sink never appeared, so it was removed. Audio is untouched." >&2
      echo "Check: systemctl --user status $unit_name" >&2
      exit 1
    fi

    # Confirm the output really landed on the sink this tuning was measured for.
    for _ in {1..20}; do
      [[ "$(tuning_downstream_sink)" == "$speaker_sink" ]] && break
      sleep 0.25
    done
    downstream="$(tuning_downstream_sink)"
    if [[ $downstream != "$speaker_sink" ]]; then
      systemctl --user stop "$unit_name" >/dev/null 2>&1
      rm -f "$fragment" "$host_config"
      echo "The tuning output linked to ${downstream:-nothing} instead of" >&2
      echo "$speaker_sink, so it was removed rather than left tuning the wrong" >&2
      echo "device. Audio is untouched." >&2
      exit 1
    fi

    pactl set-default-sink "$sink_name" >/dev/null 2>&1
    # A default sink only captures newly created streams, so anything already
    # playing would keep bypassing the tuning until its app was restarted.
    move_apps_to "$sink_name"

    echo "Speakers now play through the tuning."
    ;;

  *)
    echo "Usage: omanix-audio-tuning <on|off|status|match|fronted-sink> [--force]" >&2
    exit 2
    ;;
esac
