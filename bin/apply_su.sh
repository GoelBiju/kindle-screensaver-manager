#!/bin/sh
# Apply converted screensavers (swipe to unlock/ad mode)

OUTPUT_DIR="/mnt/us/.screensavers_converted"
ASSETS_DIR="/mnt/us/system/.assets"
ADUNITS_DIR="/var/local/adunits"
RESOURCES_DIR="/mnt/us/extensions/screensaver/resources"

# Check for converted images
if [ ! -d "$OUTPUT_DIR" ] || [ -z "$(ls -A "$OUTPUT_DIR" 2>/dev/null)" ]; then
    echo "No converted images!"
    echo "Run 'Convert Images' first"
    exit 1
fi

mntroot rw 2>/dev/null

# Unlock application registry 
# (just in the event if it was already locked)
chattr -i "$ADUNITS_DIR/admgr.json" 2>/dev/null
chattr -i "$ADUNITS_DIR" 2>/dev/null

# Backup the current ads we have 
# (better than deleting as there is a chance deleting might stop services) 

echo "Backing up ads"
mv /var/local/adunits /var/local/adunits_bkp/
mv /mnt/us/system/.assets /mnt/us/system/.assets_bkp/


# Process the screensavers and convert into assets and ad entries
echo "Processing screensavers..."
COUNT=0
for IMAGE in "$OUTPUT_DIR"/bg_ss*.png; do
    if [ -f "$IMAGE" ]; then
        # Make a new asset file
        mkdir "$ASSETS_DIR/$COUNT"

        # Copy the image
        FILENAME=$(basename "$IMAGE")
        cp "$IMAGE" "$ASSETS/$COUNT/screensvr.png" 2>/dev/null
        cp "$IMAGE" "$ASSETS/$COUNT/screensvr_active.png" 2>/dev/null

        # Copy over the other assets
        # cp "

        COUNT=$((COUNT + 1))
    fi
done


# Check if we are in ad-mode or not
# Ensure we enter
echo "Checking ad-mode..."
DB="/var/local/appreg.db"
STATE=$(sqlite3 "$DB" 'select value from properties where name = "adunit.viewable";')

if [ "$STATE" = "true" ]; then  
    echo "Ads are currently ENABLED"
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


# Show completion
echo "Screensavers Applied!"
echo "Installed: $COUNT images"

# Check if we are in ad-mode or not
# Ensure we enter
echo "Checking ad-mode..."
DB="/var/local/appreg.db"
STATE=$(sqlite3 "$DB" 'select value from properties where name = "adunit.viewable";')

if [ "$STATE" = "true" ]; then
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
