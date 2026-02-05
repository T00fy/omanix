#!/usr/bin/env bash

# 1. Detect Browser
# Priority:
# 1. Environment Variable (Injected by Nix)
# 2. XDG Settings (Runtime detection)
# 3. Hardcoded Fallback
detected_browser=$(xdg-settings get default-web-browser 2>/dev/null)
browser_target="${detected_browser:-$OMANIX_BROWSER_FALLBACK}"

# 2. Determine Executable and Private Flag
# Functional Parity: Matches original regex logic
if [[ "$browser_target" == *"firefox"* ]]; then
    exec_name="firefox"
    private_flag="--private-window"
elif [[ "$browser_target" == *"chromium"* || "$browser_target" == *"chrome"* || "$browser_target" == *"brave"* ]]; then
    exec_name="chromium"
    private_flag="--incognito"
else
    # Default fallback
    exec_name="firefox"
    private_flag="--private-window"
fi

# 3. Execute
# Functional Parity: Handles --private argument logic
if [[ "$1" == "--private" ]]; then
    # Shift args to remove --private, pass the rest
    shift
    exec "$exec_name" "$private_flag" "$@"
else
    exec "$exec_name" "$@"
fi
