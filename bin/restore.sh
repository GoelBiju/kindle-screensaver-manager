#!/bin/sh
# Restore original screensavers, ads and ad setting
#
# Undoes every mode that has been applied, whatever order they were applied in.

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/backup.sh"

FLAG_FILE="/mnt/us/extensions/screensaver/.mode_flag"

if ! blanket_backed_up && ! ads_backed_up && [ ! -f "$STATE_AD_VIEWABLE" ]; then
    err "No backups found!"
    err "Nothing to restore"
    exit 1
fi

mntroot rw 2>/dev/null

FAILED=false
NEEDS_REBOOT=false

# Backups made before the original ad setting was recorded: fill it in
# now (assumes ads were on if an ad backup exists) so it gets restored.
save_ad_viewable

# Book cover mode: default screensavers
restore_blanket
case $? in
    0) msg "Restored default screensavers" ;;
    1) err "Failed to restore default screensavers!"; FAILED=true ;;
esac

# Swipe unlock mode (or book cover mode on an ad device): original ads
restore_ads
case $? in
    0) msg "Restored original ads"; NEEDS_REBOOT=true ;;
    1) err "Failed to restore original ads!"; FAILED=true ;;
esac

# Original ad on/off setting
if [ "$FAILED" = "false" ]; then
    if restore_ad_viewable; then
        msg "Restored ad setting ($(get_ad_viewable))"
        NEEDS_REBOOT=true
    fi
    rm -f "$FLAG_FILE"
    rmdir "$STATE_DIR" 2>/dev/null
fi

mntroot ro 2>/dev/null

if [ "$FAILED" = "true" ]; then
    err "Restore incomplete, backups kept"
    exit 1
fi

if [ "$NEEDS_REBOOT" = "true" ]; then
    msg "Rebooting to apply changes..."
    sleep 3
    reboot
else
    msg "Restore complete!"
    exit 0
fi
