#!/usr/bin/env bash

# Power menu — rofi driven (reboot / sleep / shutdown / lock / logout)
# Uses systemd (systemctl) for system actions.

lock()    { i3lock --color 2e3440 --blur 5; }
logout()  { i3-msg exit; }
sleep()   { systemctl suspend; }
reboot()  { systemctl reboot; }
shutdown(){ systemctl poweroff; }

options="  Lock\n  Logout\n  Sleep\n  Reboot\n  Shutdown"

choice=$(echo -e "$options" | rofi -dmenu -i -p "Power" \
    -theme-str 'window {width: 200px;} listview {lines: 5;}')

case "$choice" in
    *Lock)     lock ;;
    *Logout)   logout ;;
    *Sleep)    sleep ;;
    *Reboot)   reboot ;;
    *Shutdown) shutdown ;;
esac
