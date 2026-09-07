#!/usr/bin/env bash

# omanix:summary=Detect an Intel SOF (Sound Open Firmware) audio controller (exit code)

# Consumed by the audio-tuning setup (Q4-03): SOF/Smart-Sound machines need
# DSP-specific handling that plain HD-Audio boxes do not. Exits 0 when the
# Intel SOF / Smart Sound Technology controller signature is present in lspci,
# 1 otherwise. (Audio controllers carry no suspend penalty, so lspci is fine
# here — unlike the GPU probe.)
lspci 2>/dev/null \
  | grep -iE 'intel' \
  | grep -iqE 'sound open firmware|smart sound|multimedia audio' && exit 0

exit 1
