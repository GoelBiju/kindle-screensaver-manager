#!/bin/sh
# Apply converted screensavers (book cover mode/non-ad mode)

OUTPUT_DIR="/mnt/us/.screensavers_converted"
BACKUP_DIR="/usr/share/blanket/screensaver_bkp"
DEST_DIR="/usr/share/blanket/screensaver"

# Check if blanket screensaver folder exists
if [ ! -d "$DEST_DIR" ]; then
    echo "Unable to find blanket service screensaver folder ($DEST_DIR)"
    echo "This method might not work"
    exit 1
fi

# Check for converted images
if [ ! -d "$OUTPUT_DIR" ] || [ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
    echo "No converted images!"
    echo "Run 'Convert Images' first"
    exit 1
fi

# Backup if needed
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    echo "Backing up originals..."
    mkdir -p "$BACKUP_DIR"
    mntroot rw 2>/dev/null
    cp -p "$DEST_DIR"/* "$BACKUP_DIR/" 2>/dev/null
else
    mntroot rw 2>/dev/null
fi

# TODO: Should we do a reboot or unload of screensaver as we are removing existing screensavers,
#       can cause the blanket service to crash

# Clear current contents of DEST_DIR (default screensavers)
rm -r "$DEST_DIR"/*

# Copy files
echo "Copying files..."
COUNT=0
for IMAGE in "$OUTPUT_DIR"/*; do
    if [ -f "$IMAGE" ]; then
        FILENAME=$(basename "$IMAGE")
        cp "$IMAGE" "$DEST_DIR/$FILENAME" 2>/dev/null && COUNT=$((COUNT + 1))
    fi
done

# Show completion
echo "Screensavers Applied!"
echo "Installed: $COUNT images"

# Check if we are in ad-mode or not
# Ensure we enter
echo "Checking ad-mode..."
DB="/var/local/appreg.db"
STATE=$(sqlite3 "$DB" 'select value from properties where name = "adunit.viewable";')

if [ "$STATE" = "true" ]; then
    # Unlock
    chattr -i "$ADUNITS_DIR/admgr.json" 2>/dev/null
    chattr -i "$ADUNITS_DIR" 2>/dev/null

    # Backup ads 
    echo "Ads are currently ENABLED."
    echo "Backing up ads"
    mv /var/local/adunits /var/local/adunits_bkp/
    mv /mnt/us/system/.assets /mnt/us/system/.assets_bkp/
    echo "Updating appreg.db..."
    sqlite3 "$DB" 'update properties set value = "false" where name = "adunit.viewable";'

    mntroot ro 2>/dev/null
    echo "Ads disabled and backed up. Rebooting in 5 seconds..."
    sleep 5
    reboot
# else
#     echo "Ads are currently DISABLED."
#     echo "Re-enabling ads..."
#     sqlite3 "$DB" 'update properties set value = "true" where name = "adunit.viewable";'
#     echo "Ads enabled. Rebooting in 5 seconds..."
#     sleep 5
#     reboot
    mntroot ro 2>/dev/null
fi
