#!/bin/sh
# backup.sh - shared backup/restore helpers for Screensaver Manager
#
# Source after common.sh:
#   . "$(dirname "$0")/backup.sh"
#
# Backups are taken once, the first time a mode needs them, and are only
# removed by a successful restore. Small state files remember what the
# device looked like before we touched it, so restore can put it back
# regardless of which mode(s) were applied in between.
#
# Callers must run "mntroot rw" before using the blanket helpers.

DB="/var/local/appreg.db"

ADUNITS_DIR="/var/local/adunits"
ADUNITS_BACKUP="/var/local/adunits_bkp"
ASSETS_DIR="/mnt/us/system/.assets"
ASSETS_BACKUP="/mnt/us/system/.assets_bkp"

BLANKET_DIR="/usr/share/blanket/screensaver"
BLANKET_BACKUP="/usr/share/blanket/screensaver_bkp"

# Kept on /var/local so it survives reinstalling the extension folder
STATE_DIR="/var/local/screensaver_mgr"
STATE_AD_VIEWABLE="${STATE_DIR}/adunit_viewable"   # original adunit.viewable value
STATE_ADS="${STATE_DIR}/ads_backup"                # "present" or "absent"

## Ad setting (appreg.db)

get_ad_viewable()
{
    sqlite3 "$DB" 'select value from properties where name = "adunit.viewable";' 2>/dev/null
}

set_ad_viewable()
{
    sqlite3 "$DB" "update properties set value = \"$1\" where name = \"adunit.viewable\";"
}

# Remember the original ad setting, once, before anything changes it.
save_ad_viewable()
{
    [ -f "$STATE_AD_VIEWABLE" ] && return 0
    mkdir -p "$STATE_DIR"

    if [ -d "$ADUNITS_BACKUP" ]; then
        # Backups from before state tracking existed: the setting may already
        # have been changed, so assume ads were on (a backup implies they existed).
        echo "true" > "$STATE_AD_VIEWABLE"
    else
        get_ad_viewable > "$STATE_AD_VIEWABLE"
    fi
}

## Ads (adunits + assets)

ads_backed_up()
{
    [ -f "$STATE_ADS" ] || [ -d "$ADUNITS_BACKUP" ]
}

unlock_ads()
{
    chattr -i "$ADUNITS_DIR/admgr.json" 2>/dev/null
    chattr -i "$ADUNITS_DIR" 2>/dev/null
}

# Only call once the originals are backed up: everything left is ours.
remove_custom_ads()
{
    unlock_ads
    rm -rf "$ADUNITS_DIR" "$ASSETS_DIR" 2>/dev/null
}

# Back up the original ads, once. Returns non-zero on failure.
backup_ads()
{
    mkdir -p "$STATE_DIR"

    if [ -f "$STATE_ADS" ]; then
        return 0
    fi
    if [ -d "$ADUNITS_BACKUP" ]; then
        # Backup from before state tracking existed
        echo "present" > "$STATE_ADS"
        return 0
    fi

    unlock_ads
    if [ -d "$ADUNITS_DIR" ] && ! grep -q "Custom Screensaver" "$ADUNITS_DIR/admgr.json" 2>/dev/null; then
        msg "Backing up original ads (first time)..."
        mv "$ADUNITS_DIR" "$ADUNITS_BACKUP" || return 1
        if [ -d "$ASSETS_DIR" ]; then
            mv "$ASSETS_DIR" "$ASSETS_BACKUP" || return 1
        fi
        echo "present" > "$STATE_ADS"
    else
        # No original ads on this device (or only leftovers of ours)
        echo "absent" > "$STATE_ADS"
    fi
    return 0
}

# Put the original ads back. Returns 0 if restored, 1 on failure,
# 2 if there was nothing to restore.
restore_ads()
{
    ads_backed_up || return 2

    _state="$(cat "$STATE_ADS" 2>/dev/null)"
    [ -z "$_state" ] && _state="present"

    remove_custom_ads

    if [ "$_state" = "present" ]; then
        if [ ! -d "$ADUNITS_BACKUP" ]; then
            err "Ad backup is missing!"
            return 1
        fi
        # Older versions could mv a folder *into* an existing backup,
        # leaving our custom ads nested inside it. Drop those.
        rm -rf "$ADUNITS_BACKUP/adunits" "$ASSETS_BACKUP/.assets" 2>/dev/null

        mv "$ADUNITS_BACKUP" "$ADUNITS_DIR" || return 1
        if [ -d "$ASSETS_BACKUP" ]; then
            mv "$ASSETS_BACKUP" "$ASSETS_DIR" || return 1
        fi
    fi

    rm -f "$STATE_ADS"
    return 0
}

# Put the original ad setting back. Returns 0 if it changed.
restore_ad_viewable()
{
    [ -f "$STATE_AD_VIEWABLE" ] || return 1
    _orig="$(cat "$STATE_AD_VIEWABLE")"
    rm -f "$STATE_AD_VIEWABLE"

    [ -z "$_orig" ] && return 1
    [ "$(get_ad_viewable)" = "$_orig" ] && return 1

    set_ad_viewable "$_orig"
    return 0
}

## Blanket screensavers (book cover mode)

blanket_backed_up()
{
    [ -d "$BLANKET_BACKUP" ] && [ -n "$(ls -A "$BLANKET_BACKUP" 2>/dev/null)" ]
}

# Back up the default screensavers, once. Returns non-zero on failure.
backup_blanket()
{
    blanket_backed_up && return 0

    msg "Backing up original screensavers (first time)..."
    mkdir -p "$BLANKET_BACKUP"
    if ! cp -p "$BLANKET_DIR"/* "$BLANKET_BACKUP/"; then
        rm -rf "$BLANKET_BACKUP"
        return 1
    fi
    return 0
}

# Put the default screensavers back. Returns 0 if restored, 1 on failure,
# 2 if there was nothing to restore.
restore_blanket()
{
    blanket_backed_up || return 2

    lipc-set-prop com.lab126.blanket unload screensaver 2>/dev/null
    rm -rf "$BLANKET_DIR"/* 2>/dev/null
    if ! cp -p "$BLANKET_BACKUP"/* "$BLANKET_DIR/"; then
        lipc-set-prop com.lab126.blanket load screensaver 2>/dev/null
        return 1
    fi
    lipc-set-prop com.lab126.blanket load screensaver 2>/dev/null

    rm -rf "$BLANKET_BACKUP"
    return 0
}
