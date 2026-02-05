#!/usr/bin/env bash

hyprctl clients -j | jq -r ".[].address" | xargs -r -I{} hyprctl dispatch closewindow address:{}
sleep 1
systemctl reboot
