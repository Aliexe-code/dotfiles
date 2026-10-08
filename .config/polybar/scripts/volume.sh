#!/usr/bin/env bash
# Polybar volume module — reads/writes volume through PulseAudio/PipeWire via pamixer.
# Supports action args so the bar can change volume with the mouse wheel / clicks.
#   (no arg)   -> print current state
#   --inc N    -> increase volume by N and print
#   --dec N    -> decrease volume by N and print
#   --mute     -> toggle mute and print

case "${1:-}" in
    --inc) pamixer -i "${2:-5}";;
    --dec) pamixer -d "${2:-5}";;
    --mute) pamixer -t;;
esac

mute=$(pamixer --get-mute 2>/dev/null)
vol=$(pamixer --get-volume 2>/dev/null)

if [[ "$mute" == "true" ]]; then
    printf "MUTED"
else
    printf "%3d%%" "$vol"
fi
