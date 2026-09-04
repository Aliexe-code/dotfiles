#!/usr/bin/env bash
# Power menu for waybar (niri). Opens fuzzel with shutdown / reboot / sleep.

choice=$(
  printf 'Shutdown\0icon\x1fsystem-shutdown\nReboot\0icon\x1fsystem-reboot\nSleep\0icon\x1fsystem-suspend\n' \
    | fuzzel --dmenu \
        --prompt="Power: " \
        --lines=3 \
        --width=20 \
        --anchor=top-right \
        --x-margin=12 \
        --y-margin=8 \
        --minimal-lines
)

case "$choice" in
  Shutdown) exec systemctl poweroff ;;
  Reboot)   exec systemctl reboot ;;
  Sleep)    exec systemctl suspend ;;
esac
