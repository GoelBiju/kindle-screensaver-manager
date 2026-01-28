# Screensaver Manager - KUAL Extension

Simple KUAL extension for managing custom screensavers on jailbroken Kindle.

## Installation

1. **Add required binaries:**
   - Place your ARM ffmpeg binary at: `screensaver/bin/ffmpeg`
   - Place FBInk binary at: `screensaver/bin/fbink`

2. **Copy to Kindle:**
   - Copy the `screensaver` folder to `/mnt/us/extensions/`

3. **Make scripts executable:**
   ```bash
   chmod +x /mnt/us/extensions/screensaver/bin/*.sh
   chmod +x /mnt/us/extensions/screensaver/bin/ffmpeg
   chmod +x /mnt/us/extensions/screensaver/bin/fbink
   ```

4. **Launch KUAL:**
   - Open KUAL on your Kindle
   - You'll see "Screensaver Manager" in the menu

## Usage

1. **Add images:**
   - Copy your images (jpg, png, etc.) to `/mnt/us/screensavers/`

2. **Convert & Apply:**
   - Open KUAL
   - Navigate to "Screensaver Manager"
   - Select "Convert & Apply"

3. **View screensavers:**
   - Put Kindle to sleep
   - Wake to see your custom screensavers!

## Menu Options

- **Convert Images** - Process images from source folder
- **Apply Screensavers** - Install converted images to Kindle
- **Convert & Apply** - Do both in one step
- **Restore Defaults** - Restore original Kindle screensavers
- **Show Status** - View counts and configuration

## Configuration

Edit the variables at the top of each script to customize:

- Resolution (default: 600x800 for Kindle Basic)
- Source/output directories
- Binary locations

## Supported Resolutions

- Kindle Basic (KT4): 600x800
- Kindle Paperwhite 3: 758x1024
- Kindle Paperwhite 4/5: 1072x1448
- Kindle Oasis: 1264x1680
- Kindle Scribe: 1860x2480

## Requirements

- Jailbroken Kindle
- KUAL installed
- ffmpeg binary for ARM architecture
- FBInk binary (get from: https://github.com/NiLuJe/FBInk/releases)

## Where to get FBInk

Download the latest FBInk release for Kindle:
https://github.com/NiLuJe/FBInk/releases

Look for `fbink-vX.X.X-kindlexxx.tar.xz` matching your Kindle model.
Extract and copy the `fbink` binary to `screensaver/bin/`

## Troubleshooting

**"ffmpeg missing" error:**
- Ensure ffmpeg is in `bin/ffmpeg`
- Make it executable: `chmod +x bin/ffmpeg`

**"fbink missing" or blank screen:**
- Download FBInk from the link above
- Place in `bin/fbink`
- Make it executable: `chmod +x bin/fbink`

**No images found:**
- Check images are in `/mnt/us/screensavers/`
- Supported formats: png, jpg, jpeg, gif, bmp

**Apply fails:**
- Ensure `mntroot` command is available
- May need root access
