#!/usr/bin/env bash

# 1. Ensure background services are running
# Elephant is the data provider for Walker
if ! pgrep -x elephant > /dev/null; then
  systemctl --user start elephant.service
  sleep 0.5
fi

# Ensure walker service (the background daemon) is running
if ! pgrep -f "walker --gapplication-service" > /dev/null; then
  systemctl --user start walker.service
  sleep 0.3
fi

# 2. Launch Walker with specific Omanix dimensions
# Functional Parity: Uses the exact dimensions from the original script
# We use the WALKER_BIN variable injected by the Nix wrapper
exec "${WALKER_BIN:-walker}" --width 644 --maxheight 300 --minheight 300 "$@"
