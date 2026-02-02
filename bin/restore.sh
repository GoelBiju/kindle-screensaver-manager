#!/bin/sh
# Restore original screensavers

BACKUP_DIR="/usr/share/blanket/screensaver_bkp"
DEST_DIR="/usr/share/blanket/screensaver"
ADUNITS_BACKUP="/var/local/adunits_bkp"
ASSETS_BACKUP="/mnt/us/system/.assets_bkp"
FLAG_FILE="/mnt/us/extensions/screensaver/.mode_flag"

# Check if we have any backups
HAS_DEFAULT_BACKUP=false
HAS_AD_BACKUP=false

if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    HAS_DEFAULT_BACKUP=true
fi

if [ -d "$ADUNITS_BACKUP" ] && [ -d "$ASSETS_BACKUP" ]; then
    HAS_AD_BACKUP=true
fi

if [ "$HAS_DEFAULT_BACKUP" = "false" ] && [ "$HAS_AD_BACKUP" = "false" ]; then
    echo "No backups found!"
    exit 1
fi

mntroot rw 2>/dev/null

# Check what mode we're currently in
CURRENT_MODE="default"
if [ -f "$FLAG_FILE" ]; then
    CURRENT_MODE=$(cat "$FLAG_FILE")
fi

echo "Current mode: $CURRENT_MODE"
NEEDS_REBOOT=false

# Restore based on current mode
if [ "$CURRENT_MODE" = "admode" ]; then
    echo "Restoring ad-mode backups..."

    if [ "$HAS_AD_BACKUP" = "false" ]; then
        echo "ERROR: No ad-mode backup found!"
        mntroot ro 2>/dev/null
        exit 1
    fi

    # Unlock ad manager
    chattr -i /var/local/adunits/admgr.json 2>/dev/null
    chattr -i /var/local/adunits 2>/dev/null

    # Remove custom screensavers
    rm -rf /var/local/adunits 2>/dev/null
    rm -rf /mnt/us/system/.assets 2>/dev/null

    # Restore original ads
    mv "$ADUNITS_BACKUP" /var/local/adunits 2>/dev/null
    mv "$ASSETS_BACKUP" /mnt/us/system/.assets 2>/dev/null

    # Remove flag
    rm -f "$FLAG_FILE"

    echo "Original ads restored!"
    NEEDS_REBOOT=true
else
    echo "Restoring default screensavers..."

    if [ "$HAS_DEFAULT_BACKUP" = "false" ]; then
        echo "ERROR: No default screensaver backup found!"
        mntroot ro 2>/dev/null
        exit 1
    fi

    # Clear current contents of DEST_DIR (default screensavers)
    rm -rf "$DEST_DIR"/* 2>/dev/null

    # Restore files
    COUNT=0
    for IMAGE in "$BACKUP_DIR"/*; do
        if [ -f "$IMAGE" ]; then
            FILENAME=$(basename "$IMAGE")
            cp "$IMAGE" "$DEST_DIR/$FILENAME" 2>/dev/null && COUNT=$((COUNT + 1))
        fi
    done

    # Remove the backup directory
    rm -rf "$BACKUP_DIR" 2>/dev/null
    
    echo "Restored default screensavers! ($COUNT images)"

    # If device originally had ads, restore them
    if [ "$HAS_AD_BACKUP" = "true" ]; then
        echo "Restoring to ad-supported mode..."

        # Restore the ad backups
        mv "$ADUNITS_BACKUP" /var/local/adunits 2>/dev/null
        mv "$ASSETS_BACKUP" /mnt/us/system/.assets 2>/dev/null
        
        # Enable ads
        DB="/var/local/appreg.db"
        sqlite3 "$DB" 'update properties set value = "true" where name = "adunit.viewable";'
        
        NEEDS_REBOOT=true
    fi

    # Remove flag
    rm -f "$FLAG_FILE"
fi

mntroot ro 2>/dev/null

if [ "$NEEDS_REBOOT" = "true" ]; then
    echo "Rebooting to apply changes..."
    sleep 2
    reboot
else
    echo "Restore complete!"
    exit 0
fi
