# BolideOS: Override MCE default config for power optimization
# Replaces upstream builtin-gconf.values with power-optimized defaults:
#  - orientation_change_is_activity=false (critical: prevents accel keeping screen on)
#  - 15s dim + 3s blank timeout
#  - No blank inhibit, no blanking pause
#  - autosuspend=early
#  - No fake doubletap, no wrist sensor

FILESEXTRAPATHS:prepend := "${THISDIR}/mce:"
SRC_URI:append = " file://builtin-gconf.values"

do_install:append() {
    install -m 0644 ${UNPACKDIR}/builtin-gconf.values ${D}${localstatedir}/lib/mce/
}
