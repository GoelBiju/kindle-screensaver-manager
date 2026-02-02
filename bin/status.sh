#!/bin/sh
# Show status

SOURCE_DIR="/mnt/us/screensavers"
OUTPUT_DIR="/mnt/us/.screensavers_converted"
FFMPEG_BIN="/mnt/us/extensions/screensaver/bin/ffmpeg"

# Count files
# SOURCE_COUNT=$(find "$SOURCE_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | wc -l)
CONVERTED_COUNT=$(find "$OUTPUT_DIR" -type f -iname "*.png" 2>/dev/null | wc -l)

if [ -x "$FFMPEG_BIN" ]; then
    FFMPEG_STATUS="Ready"
else
    FFMPEG_STATUS="MISSING"
fi

# Display status
# echo "Source: $SOURCE_COUNT images"
# echo "Converted: $CONVERTED_COUNT images"

# Check ffmpeg status
# echo "FFmpeg: $FFMPEG_STATUS"


# Get current resolution from eips
SCREEN_INFO=$(eips -i 2>/dev/null)

# Extract dimensions
KINDLE_WIDTH=$(echo "$SCREEN_INFO" | grep "xres:" | awk '{print $2}')
KINDLE_HEIGHT=$(echo "$SCREEN_INFO" | grep "yres:" | awk '{print $4}')

# Fallback to default if extraction fails
KINDLE_WIDTH=${KINDLE_WIDTH:-600}
KINDLE_HEIGHT=${KINDLE_HEIGHT:-800}

echo "Detected screen: ${KINDLE_WIDTH}x${KINDLE_HEIGHT}"
# echo "Resolution: 600x800"

exit 0
