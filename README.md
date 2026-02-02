# Kindle Screensaver Manager - KUAL Extension

A KUAL extension for managing custom screensavers on your jailbroken Kindle. Tested on Kindle Basic 4 (KT4) on firmware version `5.18.1`.

## Features

...

## TODOs

- [ ] display printing to screen
- [ ] combine convert into the apply scripts
- [ ] book cover toggle/switch between cover and custom wallpapers
- [ ] active screen vs locked screen (ad mode specific)
- [ ] bin install package
- [ ] toggle transparent screen (no screensavers)
- [ ] book covers on ad-mode/swipe to unlock screen
- [ ] unlocking on ad, scrolls in home page
- [ ] minimise the extra assets and admgr.json entry content
- [ ] add functionality to handle different kindle screen sizes (eips)

## Installation

1. **Add required binaries:**
   - Place your ARM ffmpeg binary at: `screensaver/bin/ffmpeg`

2. **Copy to Kindle:**
   - Copy the `screensaver` folder to `/mnt/us/extensions/`

3. **Make scripts executable:**

   ```bash
   chmod +x /mnt/us/extensions/screensaver/bin/*.sh
   chmod +x /mnt/us/extensions/screensaver/bin/ffmpeg
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
- **Restore** - Restore original Kindle screensavers
- **Show Status** - View counts and configuration

## Configuration

Edit the variables at the top of each script to customize:

- Resolution (default: 600x800 for Kindle Basic)
- Source/output directories
- Binary locations

## Supported Resolutions

- Kindle Basic (KT4): 600x800

Not yet supported:

- Kindle Paperwhite 3: 758x1024
- Kindle Paperwhite 4/5: 1072x1448
- Kindle Oasis: 1264x1680
- Kindle Scribe: 1860x2480

## Requirements

- Jailbroken Kindle
- KUAL installed
- ffmpeg binary for ARM architecture

## Troubleshooting

**"ffmpeg missing" error:**

- Ensure ffmpeg is in `bin/ffmpeg`
- Make it executable: `chmod +x bin/ffmpeg`

**No images found:**

- Check images are in `/mnt/us/screensavers/`
- Supported formats: png, jpg, jpeg, gif, bmp

**Apply fails:**

- Ensure `mntroot` command is available
- Ensure you have a jailbroken kindle as you root access
