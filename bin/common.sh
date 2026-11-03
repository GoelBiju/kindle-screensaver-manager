#!/bin/sh
# common.sh - shared setup for Screensaver Manager scripts
#
# Source from the other scripts with:
#   . "$(dirname "$0")/common.sh"
#
# Provides:
#   msg  "text"   - info message (stdout + log + on-screen)
#   warn "text"   - warning message
#   err  "text"   - error message

KH_HACKNAME="screensaver"
EXT_DIR="/mnt/us/extensions/${KH_HACKNAME}"
_KH_FUNCS="${EXT_DIR}/bin/libkh5"

if [ -f "${_KH_FUNCS}" ] ; then
    . "${_KH_FUNCS}"

    # libkh5 only looks for FBInk in other hacks' folders; also accept one
    # dropped into our own bin/ (FBInk stacks lines nicely, eips doesn't).
    if [ "${FBINK_BIN}" = "true" ] && [ -x "${EXT_DIR}/bin/fbink" ] ; then
        FBINK_BIN="${EXT_DIR}/bin/fbink"
    fi
    _HAVE_KH="true"
else
    _HAVE_KH="false"
fi

# The first message of a run clears whatever the previous run left on screen.
_MSG_CLEARED="false"

_msg()
{
    _lvl="${1}"
    _txt="${2}"

    # Keep stdout output (handy over SSH and in KUAL's log)
    echo "${_txt}"

    if [ "${_HAVE_KH}" = "true" ] ; then
        if [ "${_MSG_CLEARED}" = "false" ] ; then
            kh_msg_replace "${_txt}" "${_lvl}" v
            _MSG_CLEARED="true"
        else
            kh_msg "${_txt}" "${_lvl}" v
        fi
    else
        # Bare fallback: print on the second-to-last eips row
        eips 0 38 " ${_txt}                                                  " >/dev/null 2>&1
    fi
}

msg()  { _msg I "${1}"; }
warn() { _msg W "${1}"; }
err()  { _msg E "${1}"; }

