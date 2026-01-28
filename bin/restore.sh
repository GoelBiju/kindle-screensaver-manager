#!/bin/sh
# Restore original screensavers

BACKUP_DIR="/usr/share/blanket/screensaver_bkp"
DEST_DIR="/usr/share/blanket/screensaver"

# Check backup exists
if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    echo "No backup found!"
    exit 1
fi

mntroot rw 2>/dev/null

# Clear current contents of DEST_DIR (default screensavers)
rm -r "$DEST_DIR"/*

# Restore files
COUNT=0
for IMAGE in "$BACKUP_DIR"/*; do
    if [ -f "$IMAGE" ]; then
        FILENAME=$(basename "$IMAGE")
        cp "$IMAGE" "$DEST_DIR/$FILENAME" 2>/dev/null && COUNT=$((COUNT + 1))
    fi
done

# Remove the backup directory
rm -r "$BACKUP_DIR"/*

# Check if we are not in ad-mode
echo "Checking ad-mode..."
DB="/var/local/appreg.db"
STATE=$(sqlite3 "$DB" 'select value from properties where name = "adunit.viewable";')

# We would need to reboot to ensure the ads work properly 
if [ "$STATE" = "false" ]; then
    # Put back in ads
    echo "Ads are currently DISABLED."
    echo "Restoring ads"
    mv /mnt/us/system/.assets_bkp/ /mnt/us/system/.assets
    mv /var/local/adunits_bkp /var/local/adunits/

    echo "Updating application registry (appreg.db)..."
    sqlite3 "$DB" 'update properties set value = "true" where name = "adunit.viewable";'
    mntroot ro 2>/dev/null

    echo "Ads enabled and restored. Rebooting..."
    reboot
fi

mntroot ro 2>/dev/null

# Show completion
echo "Defaults Restored!"
echo "Restored: $COUNT images"
