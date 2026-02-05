#!/usr/bin/env bash

systemctl --user restart elephant.service
sleep 0.5
systemctl --user restart walker.service
notify-send "Walker" "Services have been restarted"
