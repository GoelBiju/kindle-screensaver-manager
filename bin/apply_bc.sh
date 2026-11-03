#!/bin/sh
# Apply converted screensavers (book cover mode/non-ad mode)

. "$(dirname "$0")/common.sh"

SCRIPT_DIR="/mnt/us/extensions/screensaver/bin"
OUTPUT_DIR="/mnt/us/.screensavers_converted"
BACKUP_DIR="/usr/share/blanket/screensaver_bkp"
DEST_DIR="/usr/share/blanket/screensaver"
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

# Backup default screensavers (only if backup doesn't exist)
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    msg "Backing up original screensavers (first time)..."
    mkdir -p "$BACKUP_DIR"
    cp -p "$DEST_DIR"/* "$BACKUP_DIR/" 2>/dev/null
fi

# TODO: Should we do a reboot or unload of screensaver as we are removing existing screensavers,
#       can cause the blanket service to crash

# Clear current contents of DEST_DIR (default screensavers)
rm -r "$DEST_DIR"/*

# Copy files
msg "Copying files..."
COUNT=0
for IMAGE in "$OUTPUT_DIR"/*; do
    if [ -f "$IMAGE" ]; then
        FILENAME=$(basename "$IMAGE")
        cp "$IMAGE" "$DEST_DIR/$FILENAME" 2>/dev/null && COUNT=$((COUNT + 1))
    fi
done

# Show completion
msg "Screensavers Applied!"
msg "Installed: $COUNT images"

# Check if we are in ad-mode or not
msg "Checking ad-mode..."
DB="/var/local/appreg.db"
STATE=$(sqlite3 "$DB" 'select value from properties where name = "adunit.viewable";')

NEEDS_REBOOT=false

if [ "$STATE" = "true" ]; then
    # Unlock
    chattr -i "$ADUNITS_DIR/admgr.json" 2>/dev/null
    chattr -i "$ADUNITS_DIR" 2>/dev/null

    # Backup ads (only if backup doesn't exist)
    if [ ! -d "/var/local/adunits_bkp" ]; then
        msg "Ads are currently ENABLED."
        msg "Backing up original ads (first time)..."
        mv /var/local/adunits /var/local/adunits_bkp/ 2>/dev/null
        mv /mnt/us/system/.assets /mnt/us/system/.assets_bkp/ 2>/dev/null
    else
        msg "Ads are currently ENABLED."
        msg "Ad backup already exists, removing current ads..."
        rm -rf /var/local/adunits 2>/dev/null
        rm -rf /mnt/us/system/.assets 2>/dev/null
    fi

    msg "Updating appreg.db..."
    sqlite3 "$DB" 'update properties set value = "false" where name = "adunit.viewable";'
    NEEDS_REBOOT=true
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
