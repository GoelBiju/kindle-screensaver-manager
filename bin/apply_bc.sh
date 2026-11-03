#!/bin/sh
# Apply converted screensavers (book cover mode/non-ad mode)

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/backup.sh"

SCRIPT_DIR="/mnt/us/extensions/screensaver/bin"
OUTPUT_DIR="/mnt/us/.screensavers_converted"
BACKUP_DIR="$BLANKET_BACKUP"
DEST_DIR="$BLANKET_DIR"
FLAG_FILE="/mnt/us/extensions/screensaver/.mode_flag"

# Check if blanket screensaver folder exists
if [ ! -d "$DEST_DIR" ]; then
    err "Unable to find blanket service screensaver folder ($DEST_DIR)"
    err "This method might not work"
    exit 1
fi

# Run conversion
msg "Converting images..."
"$SCRIPT_DIR/convert.sh"

# Check for converted images
if [ $? -ne 0 ] || [ ! -d "$OUTPUT_DIR" ] || [ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
    err "No converted images!"
    err "Add images to /mnt/us/screensavers/"
    exit 1
fi

# The blanket folder lives on the (normally read-only) root filesystem
mntroot rw 2>/dev/null
if ! touch "$DEST_DIR/.rw_test" 2>/dev/null; then
    err "Root filesystem is read-only!"
    err "Could not run 'mntroot rw'"
    exit 1
fi
rm -f "$DEST_DIR/.rw_test"

# Backup default screensavers (first time only)
if ! backup_blanket; then
    err "Backup of default screensavers failed!"
    mntroot ro 2>/dev/null
    exit 1
fi

# Unload the screensaver module while we swap files, so blanket
# doesn't try to read a half-empty folder
lipc-set-prop com.lab126.blanket unload screensaver 2>/dev/null

# Clear current contents of DEST_DIR (default screensavers)
rm -rf "$DEST_DIR"/*

# Copy files
msg "Copying files..."
COUNT=0
for IMAGE in "$OUTPUT_DIR"/*; do
    if [ -f "$IMAGE" ]; then
        FILENAME=$(basename "$IMAGE")
        cp "$IMAGE" "$DEST_DIR/$FILENAME" && COUNT=$((COUNT + 1))
    fi
done

if [ $COUNT -eq 0 ]; then
    err "Copy failed! Putting defaults back..."
    cp -p "$BACKUP_DIR"/* "$DEST_DIR/" 2>/dev/null
    lipc-set-prop com.lab126.blanket load screensaver 2>/dev/null
    mntroot ro 2>/dev/null
    exit 1
fi

# Reload the screensaver module so it picks up the new images
lipc-set-prop com.lab126.blanket load screensaver 2>/dev/null

# Show completion
msg "Screensavers Applied!"
msg "Installed: $COUNT images"

# Check if we are in ad-mode or not
msg "Checking ad-mode..."
STATE=$(get_ad_viewable)

if [ "$STATE" = "true" ]; then
    msg "Ads are currently ENABLED, disabling..."
    save_ad_viewable
    if ! backup_ads; then
        err "Backup of original ads failed!"
        mntroot ro 2>/dev/null
        exit 1
    fi
    remove_custom_ads
    set_ad_viewable "false"
elif ads_backed_up; then
    # Ads already off, but swipe mode may have left its locked files behind
    remove_custom_ads
fi

# Set mode flag
echo "default" > "$FLAG_FILE"

mntroot ro 2>/dev/null

# Reboot if we changed ad state
if [ "$STATE" = "true" ]; then
    msg "Ads disabled and backed up. Rebooting..."
    sleep 3
    reboot
else
    msg "Complete! Sleep/wake to see screensavers."
    exit 0
fi
