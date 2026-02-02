#!/bin/sh
# Convert images to Kindle screensavers

SOURCE_DIR="/mnt/us/screensavers"
OUTPUT_DIR="/mnt/us/.screensavers_converted"
FFMPEG_BIN="/mnt/us/extensions/screensaver/bin/ffmpeg"

# KT4
# KINDLE_WIDTH=600
# KINDLE_HEIGHT=800

# Auto-detect screen size
echo "Detecting screen resolution..."

# Try eips first
SCREEN_INFO=$(eips -i 2>/dev/null)
if [ -n "$SCREEN_INFO" ]; then
    KINDLE_WIDTH=$(echo "$SCREEN_INFO" | grep "xres:" | awk '{print $2}')
    KINDLE_HEIGHT=$(echo "$SCREEN_INFO" | grep "yres:" | awk '{print $2}')
fi

# Fallback to model detection if eips failed
# Detect Kindle model and set screen size based on libkh5 logic
if [ -z "$KINDLE_WIDTH" ] || [ -z "$KINDLE_HEIGHT" ]; then
    echo "eips detection failed, using model detection..."
    kmfc="$(cut -c1 /proc/usid)"
    if [ "${kmfc}" == "B" ] || [ "${kmfc}" == "9" ] ; then
        kmodel="$(cut -c3-4 /proc/usid)"
        case "${kmodel}" in
            "24" | "1B" | "1D" | "1F" | "1C" | "20" | "D4" | "5A" | "D5" | "D6" | "D7" | "D8" | "F2" | "17" | "60" | "F4" | "F9" | "62" | "61" | "5F" )
                # PaperWhite 1/2
                KINDLE_WIDTH=758
                KINDLE_HEIGHT=1024
            ;;
            "13" | "54" | "2A" | "4F" | "52" | "53" )
                # Voyage
                KINDLE_WIDTH=1072
                KINDLE_HEIGHT=1448
            ;;
            "C6" | "DD" | "0F" | "11" | "10" | "12" )
                # Touch / KT2
                KINDLE_WIDTH=600
                KINDLE_HEIGHT=800
            ;;
            * )
                # Default to Touch
                KINDLE_WIDTH=600
                KINDLE_HEIGHT=800
            ;;
        esac
    else
        # New device ID scheme
        kmodel="$(cut -c4-6 /proc/usid)"
        case "${kmodel}" in
            "0G1" | "0G2" | "0G4" | "0G5" | "0G6" | "0G7" | "0KB" | "0KC" | "0KD" | "0KE" | "0KF" | "0KG" | "0LK" | "0LL" )
                # PW3
                KINDLE_WIDTH=1072
                KINDLE_HEIGHT=1448
            ;;
            "0GC" | "0GD" | "0GR" | "0GS" | "0GT" | "0GU" )
                # Oasis 1
                KINDLE_WIDTH=1072
                KINDLE_HEIGHT=1448
            ;;
            "0DU" | "0K9" | "0KA" )
                # KT3
                KINDLE_WIDTH=600
                KINDLE_HEIGHT=800
            ;;
            "0LM" | "0LN" | "0LP" | "0LQ" | "0P1" | "0P2" | "0P6" | "0P7" | "0P8" | "0S1" | "0S2" | "0S3" | "0S4" | "0S7" | "0SA" )
                # Oasis 2
                KINDLE_WIDTH=1264
                KINDLE_HEIGHT=1680
            ;;
            "0PP" | "0T1" | "0T2" | "0T3" | "0T4" | "0T5" | "0T6" | "0T7" | "0TJ" | "0TK" | "0TL" | "0TM" | "0TN" | "102" | "103" | "16Q" | "16R" | "16S" | "16T" | "16U" | "16V" )
                # PW4
                KINDLE_WIDTH=1072
                KINDLE_HEIGHT=1448
            ;;
            "10L" | "0WF" | "0WG" | "0WH" | "0WJ" | "0VB" )
                # KT4
                KINDLE_WIDTH=600
                KINDLE_HEIGHT=800
            ;;
            "11L" | "0WQ" | "0WP" | "0WN" | "0WM" | "0WL" )
                # Oasis 3
                KINDLE_WIDTH=1264
                KINDLE_HEIGHT=1680
            ;;
            "1LG" | "1Q0" | "1PX" | "1VD" | "219" | "21A" | "2BH" | "2BJ" | "2DK" )
                # PW5
                KINDLE_WIDTH=1236
                KINDLE_HEIGHT=1648
            ;;
            "22D" | "25T" | "23A" | "2AQ" | "2AP" | "1XH" | "22C" )
                # KT5
                KINDLE_WIDTH=1072
                KINDLE_HEIGHT=1448
            ;;
            "27J" | "2BL" | "263" | "227" | "2BM" | "23L" | "23M" | "270" )
                # Scribe
                KINDLE_WIDTH=1860
                KINDLE_HEIGHT=2480
            ;;
            * )
                # Default fallback
                KINDLE_WIDTH=600
                KINDLE_HEIGHT=800
            ;;
        esac
    fi

    echo "Detected Kindle model: ${kmodel}"
fi


echo "Screen resolution: ${KINDLE_WIDTH}x${KINDLE_HEIGHT}"

# Create directories
# mkdir -p "$SOURCE_DIR"

# Check for source images
if [ ! -d "$SOURCE_DIR" ] || [ -z "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
    # kh_msg "No images found in /mnt/us/screensavers/" E v
    echo "No images found in /mnt/us/screensavers/"
    # sleep 2
    exit 1
fi

# Check ffmpeg
if [ ! -x "$FFMPEG_BIN" ]; then
    echo "ERROR: ffmpeg missing!"
    echo "Add to bin/ffmpeg"
    exit 1
else
    echo "Ensuring we can execute ffmpeg..."
    chmod +x "$FFMPEG_BIN"
fi

# Create output directory and remove old conversions
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*

echo "Starting conversions..."

# Count images
# TOTAL=$(find "$SOURCE_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.bmp" \) 2>/dev/null | wc -l)

# if [ "$TOTAL" -eq 0 ]; then
#     echo "No images found!"
#     echo "Add to: $SOURCE_DIR"
#     exit 0
# fi 

# echo "Found $TOTAL images"

# Convert images using for loop (not while read)
PROCESSED=0
for IMAGE in "$SOURCE_DIR"/*.jpg "$SOURCE_DIR"/*.jpeg "$SOURCE_DIR"/*.png "$SOURCE_DIR"/*.gif "$SOURCE_DIR"/*.bmp \
             "$SOURCE_DIR"/*.JPG "$SOURCE_DIR"/*.JPEG "$SOURCE_DIR"/*.PNG "$SOURCE_DIR"/*.GIF "$SOURCE_DIR"/*.BMP; do
    
    # Skip if glob didn't match anything
    [ -f "$IMAGE" ] || continue
    
    FILENAME=$(basename "$IMAGE")
    OUTPUT_FILE="$OUTPUT_DIR/bg_ss$(printf "%03d" $PROCESSED).png"
    
    echo "Converting: $FILENAME"
    
    "$FFMPEG_BIN" -i "$IMAGE" \
        -vf "scale=${KINDLE_WIDTH}:${KINDLE_HEIGHT}:force_original_aspect_ratio=increase,crop=${KINDLE_WIDTH}:${KINDLE_HEIGHT},format=gray" \
        -pix_fmt gray \
        -y \
        "$OUTPUT_FILE" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        PROCESSED=$((PROCESSED + 1))
    else
        echo "Failed: $FILENAME"
    fi
done

# Check if any images were processed
if [ $PROCESSED -eq 0 ]; then
    echo "No images converted!"
    exit 1
fi

# Show completion
echo "Conversion Complete!"
echo "Processed: $PROCESSED images"
echo "Output: $OUTPUT_DIR"

exit 0
