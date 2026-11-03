#!/bin/sh
# Show status
#
# Kept to three short lines: FBInk stacks three lines before wrapping,
# and plain eips only shows the last one.

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/backup.sh"

OUTPUT_DIR="/mnt/us/.screensavers_converted"
FFMPEG_BIN="/mnt/us/extensions/screensaver/bin/ffmpeg"
FLAG_FILE="/mnt/us/extensions/screensaver/.mode_flag"

on_off()
{
    case "$1" in
        true) echo "on" ;;
        false) echo "off" ;;
        *) echo "n/a" ;;
    esac
}

# Mode and current ad setting
case "$(cat "$FLAG_FILE" 2>/dev/null)" in
    admode) MODE="Swipe unlock" ;;
    default) MODE="Book cover" ;;
    *) MODE="Kindle default" ;;
esac
ADS_NOW=$(on_off "$(get_ad_viewable)")

# Backups (and the ad setting we'll restore)
BACKUPS=""
blanket_backed_up && BACKUPS="screensavers"
if ads_backed_up; then
    [ -n "$BACKUPS" ] && BACKUPS="$BACKUPS, "
    BACKUPS="${BACKUPS}ads"
fi
[ -z "$BACKUPS" ] && BACKUPS="none"
if [ -f "$STATE_AD_VIEWABLE" ]; then
    BACKUPS="$BACKUPS (ads were $(on_off "$(cat "$STATE_AD_VIEWABLE")"))"
fi

# Converted images, screen size, ffmpeg
CONVERTED_COUNT=$(ls "$OUTPUT_DIR"/bg_ss*.png 2>/dev/null | wc -l | tr -d " ")

SCREEN_INFO=$(eips -i 2>/dev/null)
KINDLE_WIDTH=$(echo "$SCREEN_INFO" | grep "xres:" | awk '{print $2}')
KINDLE_HEIGHT=$(echo "$SCREEN_INFO" | grep "yres:" | awk '{print $4}')
KINDLE_WIDTH=${KINDLE_WIDTH:-600}
KINDLE_HEIGHT=${KINDLE_HEIGHT:-800}

if [ -x "$FFMPEG_BIN" ]; then
    FFMPEG_STATUS="ffmpeg OK"
else
    FFMPEG_STATUS="ffmpeg MISSING"
fi

msg "Mode: $MODE (ads $ADS_NOW)"
msg "Backups: $BACKUPS"
msg "$CONVERTED_COUNT images, ${KINDLE_WIDTH}x${KINDLE_HEIGHT}, $FFMPEG_STATUS"

exit 0
