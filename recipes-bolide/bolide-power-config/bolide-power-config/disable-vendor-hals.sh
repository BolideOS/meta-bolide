#!/bin/sh
# disable-vendor-hals: Prevents unnecessary Android vendor HALs from running.
# These are started by the hal-droid Android compat layer (vendor init).
# We can't mask them via systemd because they're managed by Android's init.
# Instead we rename their .rc files so init doesn't see them.
#
# Safe to disable on watches: NFC (no tag reader), GNSS (no GPS antenna),
# Bluetooth HAL (we use rfkill + mask bluetoothd at systemd level).

VENDOR_INIT="/vendor/etc/init"

for rc in \
    "android.hardware.nfc@1.1-service.rc" \
    "android.hardware.gnss@1.0-service.cxd5603.rc" \
    "android.hardware.bluetooth@1.0-service-qti.rc" \
; do
    if [ -f "$VENDOR_INIT/$rc" ]; then
        mv "$VENDOR_INIT/$rc" "$VENDOR_INIT/${rc}.disabled"
        logger -t disable-vendor-hals "disabled: $rc"
    fi
done

# Kill any already-running instances
for proc in "nfc@" "gnss@" "bluetooth@1.0"; do
    pkill -f "$proc" 2>/dev/null
done
