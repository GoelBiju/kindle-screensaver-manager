#!/bin/sh
# Show status

SOURCE_DIR="/mnt/us/screensavers"
OUTPUT_DIR="/mnt/us/screensavers_converted"
BACKUP_DIR="/mnt/us/screensavers_backup"
FFMPEG_BIN="/mnt/us/extensions/screensaver/bin/ffmpeg"

# Count files
SOURCE_COUNT=$(find "$SOURCE_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | wc -l)
CONVERTED_COUNT=$(find "$OUTPUT_DIR" -type f -iname "*.png" 2>/dev/null | wc -l)
BACKUP_COUNT=$(find "$BACKUP_DIR" -type f -iname "*.png" 2>/dev/null | wc -l)

if [ -x "$FFMPEG_BIN" ]; then
    FFMPEG_STATUS="Ready"
else
    FFMPEG_STATUS="MISSING"
fi

# Display status
echo "Source: $SOURCE_COUNT images"
echo "Converted: $CONVERTED_COUNT images"
echo "Backup: $BACKUP_COUNT images"
echo "FFmpeg: $FFMPEG_STATUS"
echo "Resolution: 600x800"
