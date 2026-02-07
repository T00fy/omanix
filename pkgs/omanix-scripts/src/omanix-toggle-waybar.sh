#!/usr/bin/env bash

if systemctl --user is-active --quiet waybar.service; then
  systemctl --user stop waybar.service
else
  systemctl --user start waybar.service
fi
