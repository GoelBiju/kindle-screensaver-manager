#!/bin/sh
# Apply converted screensavers (swipe to unlock/ad mode)

. "$(dirname "$0")/common.sh"
. "$(dirname "$0")/backup.sh"

SCRIPT_DIR="/mnt/us/extensions/screensaver/bin"
OUTPUT_DIR="/mnt/us/.screensavers_converted"
RESOURCES_DIR="/mnt/us/extensions/screensaver/resources"
FLAG_FILE="/mnt/us/extensions/screensaver/.mode_flag"

# Check if ad system exists on this Kindle
msg "Checking for ad system..."

# Check for ad database
if [ ! -f "$DB" ]; then
    err "appreg.db not found!"
    err "Ad system not available on this Kindle"
    exit 1
fi

# Check if adunit.viewable property exists in database
AD_PROPERTY=$(get_ad_viewable)
if [ -z "$AD_PROPERTY" ]; then
    err "Ad system not available!"
    err "This Kindle does not support ad-mode"
    err "Use 'Book Cover Mode' instead"
    exit 1
fi

# Check if /var/local/adunits path exists (or can be created)
if [ ! -d "$ADUNITS_DIR" ] && ! ads_backed_up; then
    err "/var/local/adunits never existed!"
    err "Ad system not available on this Kindle"
    err "Use 'Book Cover Mode' instead"
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

mntroot rw 2>/dev/null

# Remember the original ad setting and back up the original ads (first time only)
save_ad_viewable
if ! backup_ads; then
    err "Backup of original ads failed!"
    mntroot ro 2>/dev/null
    exit 1
fi

# Anything left in the ad folders now is ours from a previous run
remove_custom_ads

# Create the new directories
mkdir -p "$ADUNITS_DIR"
mkdir -p "$ASSETS_DIR"

# Process the screensavers and convert into assets and ad entries
msg "Processing screensavers..."
COUNT=0

# Read width/height from a PNG's IHDR chunk ("IHDR" at byte 12, then
# big-endian width and height). Prints "W H", or nothing if not a PNG.
png_size()
{
    od -An -tu1 -j12 -N12 "$1" 2>/dev/null | awk '
        { for (i = 1; i <= NF; i++) b[n++] = $i }
        END {
            if (n != 12 || b[0] != 73 || b[1] != 72 || b[2] != 68 || b[3] != 82) exit
            printf "%d %d", b[4]*16777216 + b[5]*65536 + b[6]*256 + b[7], b[8]*16777216 + b[9]*65536 + b[10]*256 + b[11]
        }'
}

# Fallback size if a header can't be read: the screen, then the KT4 default
SCREEN_INFO=$(eips -i 2>/dev/null)
FALLBACK_W=$(echo "$SCREEN_INFO" | grep "xres:" | awk '{print $2}')
FALLBACK_H=$(echo "$SCREEN_INFO" | grep "yres:" | awk '{print $4}')
FALLBACK_W=${FALLBACK_W:-600}
FALLBACK_H=${FALLBACK_H:-800}
AD_JSON_ENTRIES=""

for IMAGE in "$OUTPUT_DIR"/bg_ss*.png; do
    if [ -f "$IMAGE" ]; then
        # Copy the image
        FILENAME=$(basename "$IMAGE")

        # Make a new asset file
        mkdir -p "$ASSETS_DIR/$COUNT"

        cp "$IMAGE" "$ASSETS_DIR/$COUNT/screensvr.png" 2>/dev/null
        cp "$IMAGE" "$ASSETS_DIR/$COUNT/screensvr_active.png" 2>/dev/null

        # Copy over the other assets
        cp "$RESOURCES_DIR/banner.gif" "$ASSETS_DIR/$COUNT/" 2>/dev/null
        cp "$RESOURCES_DIR/details.html" "$ASSETS_DIR/$COUNT/" 2>/dev/null
        cp "$RESOURCES_DIR/snippet.json" "$ASSETS_DIR/$COUNT/" 2>/dev/null
        cp "$RESOURCES_DIR/thumb.gif" "$ASSETS_DIR/$COUNT/" 2>/dev/null

        # Calculate the MD5 checksum for the image
        MD5=$(md5sum "$IMAGE" | awk '{print $1}')

        # Full-screen ad area matching the converted image
        IMG_SIZE=$(png_size "$IMAGE")
        IMG_W=${IMG_SIZE% *}
        IMG_H=${IMG_SIZE#* }
        if [ -z "$IMG_SIZE" ] || [ "$IMG_W" -le 0 ] 2>/dev/null || [ "$IMG_H" -le 0 ] 2>/dev/null; then
            warn "Couldn't read size of $FILENAME, using ${FALLBACK_W}x${FALLBACK_H}"
            IMG_W=$FALLBACK_W
            IMG_H=$FALLBACK_H
        fi

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
                        \"img-location\": { \"x\": 0, \"width\": $IMG_W, \"y\": 0, \"height\": $IMG_H },
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
msg "Creating admgr.json..."
cat > "$ADUNITS_DIR/admgr.json" << EOF
{$AD_JSON_ENTRIES
}
EOF

# Lock the ad manager file from modifications, only read
chattr +i "$ADUNITS_DIR/admgr.json"
chattr +i "$ADUNITS_DIR"

# Show completion
msg "Screensavers Applied!"
msg "Installed: $COUNT images"

# Ensure we enter ad-mode on reboot
msg "Enabling ad-mode..."
set_ad_viewable "true"

# Set ad-mode flag
echo "admode" > "$FLAG_FILE"

mntroot ro 2>/dev/null
msg "Rebooting..."
sleep 3
reboot
