#!/bin/bash

# omanix:summary=Sync current Omanix theme into a running herdr
# omanix:hidden=true

# Ephemeral runtime retint of a running herdr. herdr's declared theme is
# name = "terminal" (apps/herdr.nix), so it renders on the outer terminal's
# palette, which the theme switch already retints. Reloading the server picks
# up the current palette for new panes; existing panes are best-effort. No-ops
# cleanly when no server is running.

[[ $(herdr status server --json 2>/dev/null | jq -r '.running') == "true" ]] || exit 0

herdr server reload-config >/dev/null 2>&1 || true
