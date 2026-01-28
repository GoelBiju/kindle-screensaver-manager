#!/bin/sh
# Convert images to Kindle screensavers

SOURCE_DIR="/mnt/us/screensavers"
OUTPUT_DIR="/mnt/us/.screensavers_converted"
FFMPEG_BIN="/mnt/us/extensions/screensaver/bin/ffmpeg"

# KT4
KINDLE_WIDTH=600
KINDLE_HEIGHT=800

# Create directories
mkdir -p "$SOURCE_DIR"

rm -r "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Check ffmpeg
if [ ! -x "$FFMPEG_BIN" ]; then
    echo "ERROR: ffmpeg missing!"
    echo "Add to bin/ffmpeg"
    exit 1
else
    echo "Ensuring we can execute ffmpeg..."
    chmod +x "$FFMPEG_BIN"
fi

# Count images
TOTAL=$(find "$SOURCE_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.bmp" \) 2>/dev/null | wc -l)

if [ "$TOTAL" -eq 0 ]; then
    echo "No images found!"
    echo "Add to: $SOURCE_DIR"
    exit 0
fi

echo "Found $TOTAL images"

# Convert images
PROCESSED=0
find "$SOURCE_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.bmp" \) | while read -r IMAGE; do
    FILENAME=$(basename "$IMAGE")
    OUTPUT_FILE="$OUTPUT_DIR/bg_ss$(printf "%02d" $PROCESSED).png"
    
    echo "[$PROCESSED/$TOTAL] $FILENAME                    "
    
    "$FFMPEG_BIN" -i "$IMAGE" \
        -vf "scale=${KINDLE_WIDTH}:${KINDLE_HEIGHT}:force_original_aspect_ratio=increase,crop=${KINDLE_WIDTH}:${KINDLE_HEIGHT},format=gray" \
        -pix_fmt gray \
        -y \
        "$OUTPUT_FILE" >/dev/null 2>&1

    PROCESSED=$((PROCESSED + 1))
done

# Show completion
echo "Conversion Complete!"
echo "Processed: $TOTAL images"
echo "Output: $OUTPUT_DIR"
