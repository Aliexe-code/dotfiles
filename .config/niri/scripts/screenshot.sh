#!/usr/bin/env bash
mkdir -p "$HOME/Pictures/Screenshots"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
SAVE_PATH="$HOME/Pictures/Screenshots/Screenshot_${TIMESTAMP}.png"

case "$1" in
  # Interactive region select + annotate in Satty
  area|gui|"")
    GEOM=$(slurp 2>/dev/null)
    [ -z "$GEOM" ] && exit 0
    grim -g "$GEOM" - | satty --filename - --output-filename "$SAVE_PATH"
    ;;

  # Quick region select directly to clipboard & file
  quick)
    GEOM=$(slurp 2>/dev/null)
    [ -z "$GEOM" ] && exit 0
    grim -g "$GEOM" "$SAVE_PATH"
    wl-copy < "$SAVE_PATH"
    notify-send -a "Screenshot" "Region captured" "Copied to clipboard and saved to $SAVE_PATH" -i "$SAVE_PATH" 2>/dev/null || true
    ;;

  # Full screen capture directly to clipboard & file
  full|screen)
    grim "$SAVE_PATH"
    wl-copy < "$SAVE_PATH"
    notify-send -a "Screenshot" "Screen captured" "Copied to clipboard and saved to $SAVE_PATH" -i "$SAVE_PATH" 2>/dev/null || true
    ;;

  # Select window / region and annotate in Satty
  window)
    GEOM=$(slurp 2>/dev/null)
    [ -z "$GEOM" ] && exit 0
    grim -g "$GEOM" - | satty --filename - --output-filename "$SAVE_PATH"
    ;;

  *)
    echo "Usage: $0 {area|quick|full|window}"
    exit 1
    ;;
esac
