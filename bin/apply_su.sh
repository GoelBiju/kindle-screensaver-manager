#!/bin/sh
# Apply converted screensavers (swipe to unlock/ad mode)

OUTPUT_DIR="/mnt/us/.screensavers_converted"
ASSETS_DIR="/mnt/us/system/.assets"
ADUNITS_DIR="/var/local/adunits"
RESOURCES_DIR="/mnt/us/extensions/screensaver/resources"
FLAG_FILE="/mnt/us/extensions/screensaver/.mode_flag"

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

# Backup the current ads (only if backup doesn't exist)
if [ ! -d "/var/local/adunits_bkp" ]; then
    echo "Backing up original ads (first time)..."
    if [ -d "/var/local/adunits" ]; then
        mv /var/local/adunits /var/local/adunits_bkp/ 2>/dev/null
        mv /mnt/us/system/.assets /mnt/us/system/.assets_bkp/ 2>/dev/null
    fi
else
    echo "Ad backup already exists, removing current ads..."
    rm -rf /var/local/adunits 2>/dev/null
    rm -rf /mnt/us/system/.assets 2>/dev/null
fi

# Create the new directories
mkdir -p "$ADUNITS_DIR"
mkdir -p "$ASSETS_DIR"

# Process the screensavers and convert into assets and ad entries
echo "Processing screensavers..."
COUNT=0
AD_JSON_ENTRIES=""

for IMAGE in "$OUTPUT_DIR"/bg_ss*.png; do
    if [ -f "$IMAGE" ]; then
        # Copy the image
        FILENAME=$(basename "$IMAGE")

        # Make a new asset file
        mkdir "$ASSETS_DIR/$COUNT"

        cp "$IMAGE" "$ASSETS_DIR/$COUNT/screensvr.png" 2>/dev/null
        cp "$IMAGE" "$ASSETS_DIR/$COUNT/screensvr_active.png" 2>/dev/null

        # Copy over the other assets
        cp "$RESOURCES_DIR/banner.gif" "$ASSETS_DIR/$COUNT/" 2>/dev/null
        cp "$RESOURCES_DIR/details.html" "$ASSETS_DIR/$COUNT/" 2>/dev/null
        cp "$RESOURCES_DIR/snippet.json" "$ASSETS_DIR/$COUNT/" 2>/dev/null
        cp "$RESOURCES_DIR/thumb.gif" "$ASSETS_DIR/$COUNT/" 2>/dev/null

        # Calculate the MD5 checksum for the image
        MD5=$(md5sum "$IMAGE" | awk '{print $1}')

        # Build JSON entry for this ad
        if [ $COUNT -gt 0 ]; then
            AD_JSON_ENTRIES="$AD_JSON_ENTRIES,"
        fi

        # Create an entry into the ad manager file
        AD_JSON_ENTRIES="$AD_JSON_ENTRIES
    \"$COUNT\": {
        \"cap_duration\": 86400000,
        \"hl\": \"Custom Screensaver $COUNT\",
        \"type\": \"AD\",
        \"states\": [
            {
                \"buttons\": [
                    {
                        \"state\": \"default\",
                        \"id\": 0,
                        \"creative\": \"screensvr.png\",
                        \"img-location\": { \"x\": 0, \"width\": 600, \"y\": 0, \"height\": 800 },
                        \"img-hotspot\": { \"x\": 0, \"width\": 0, \"y\": 0, \"height\": 0 }
                    }
                ],
                \"name\": \"default\"
            }
        ],
        \"ad_loc\": \"$COUNT\",
        \"screensvr_active_rect\": null,
        \"features\": false,
        \"unlock_text_color\": 15,
        \"assets\": [
            {
                \"filename\": \"thumb.gif\",
                \"checksum\": \"c691cf2e970dbc3bdad8fdabf1005134\",
                \"creative-id\": \"6007782840802\"
            },
            {
                \"filename\": \"banner.gif\",
                \"checksum\": \"7d11456e4ecefed223ad3a984b8d74ac\",
                \"creative-id\": \"6007782840802\"
            },
            {
                \"filename\": \"screensvr.png\",
                \"checksum\": \"$MD5\",
                \"creative-id\": \"6007782840802\"
            },
            {
                \"filename\": \"screensvr_active.png\",
                \"checksum\": \"$MD5\",
                \"creative-id\": \"6007782840802\"
            },
            {
                \"filename\": \"details.html\",
                \"checksum\": \"abe74f09798ed6fa28bd35e95b7d2d77\",
                \"creative-id\": \"6007782840802\"
            },
            {
                \"filename\": \"snippet.json\",
                \"checksum\": \"6d2c60e1d1162af9d053bfa93b7c408c\",
                \"creative-id\": \"6007782840802\"
            }
        ],
        \"active_ss_img\": {
            \"crea_id\": \"6007782840802\",
            \"fn\": \"screensvr_active.png\",
            \"md5\": \"$MD5\"
        },
        \"rdate\": 1893455940000,
        \"isRecommendation\": \"false\",
        \"snp_file\": {
            \"crea_id\": \"6007782840802\",
            \"fn\": \"snippet.json\",
            \"md5\": \"6d2c60e1d1162af9d053bfa93b7c408c\"
        },
        \"ss_img\": {
            \"crea_id\": \"6007782840802\",
            \"fn\": \"screensvr.png\",
            \"md5\": \"$MD5\"
        },
        \"dt_img\": {
            \"crea_id\": \"6007782840802\",
            \"fn\": \"thumb.gif\",
            \"md5\": \"c691cf2e970dbc3bdad8fdabf1005134\"
        },
        \"ver\": 20241031181042,
        \"sdate\": 1501542000000,
        \"screensvr_rect\": null,
        \"cap_count\": 501,
        \"suppress\": false,
        \"priority\": 100,
        \"edate\": 1893455940000,
        \"cta_rect\": null,
        \"rcvdate\": 1769200501875,
        \"ban_img\": {
            \"crea_id\": \"6007782840802\",
            \"fn\": \"banner.gif\",
            \"md5\": \"7d11456e4ecefed223ad3a984b8d74ac\"
        },
        \"vso-order\": 100,
        \"shl\": \"Your custom screensaver\",
        \"det_xyml\": {
            \"crea_id\": \"6007782840802\",
            \"fn\": \"details.html\",
            \"md5\": \"abe74f09798ed6fa28bd35e95b7d2d77\"
        },
        \"cta_online_uri\": null
    }"

        COUNT=$((COUNT + 1))
    fi
done


# Build complete ad manager file
echo "Creating admgr.json..."
cat > "$ADUNITS_DIR/admgr.json" << EOF
{$AD_JSON_ENTRIES
}
EOF

# Lock the ad manager file from modifications, only read
chattr +i "$ADUNITS_DIR/admgr.json"
chattr +i "$ADUNITS_DIR"

# Show completion
echo "Screensavers Applied!"
echo "Installed: $COUNT images"

# Ensure we enter ad-mode on reboot
echo "Enabling ad-mode..."
DB="/var/local/appreg.db"
sqlite3 "$DB" 'update properties set value = "true" where name = "adunit.viewable";'

# Set ad-mode flag
echo "admode" > "$FLAG_FILE"

mntroot ro 2>/dev/null
sleep 2
reboot
