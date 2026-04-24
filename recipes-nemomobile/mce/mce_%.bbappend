# BolideOS: Override MCE default config for power optimization
# Replaces upstream builtin-gconf.values with power-optimized defaults:
#  - orientation_change_is_activity=false (critical: prevents accel keeping screen on)
#  - 5s dim + 2s blank timeout (7s total — watch-appropriate)
#  - No blank inhibit, no blanking pause
#  - autosuspend=early
#  - No fake doubletap, no wrist sensor
# Also removes unnecessary MCE modules that cause wakeups on watches:
#  - cpu-keepalive (wakes CPU every 60s — designed for phone call keepalive)
#  - doubletap, packagekit, fingerprint, buttonbacklight (not applicable)

FILESEXTRAPATHS:prepend := "${THISDIR}/mce:"
SRC_URI:append = " file://builtin-gconf.values"

do_install:append() {
    install -m 0644 ${UNPACKDIR}/builtin-gconf.values ${D}${localstatedir}/lib/mce/

    # Remove unneeded MCE modules from the module list
    sed -i 's/cpu-keepalive;//' ${D}${sysconfdir}/mce/10mce.ini
    sed -i 's/doubletap;//' ${D}${sysconfdir}/mce/10mce.ini
    sed -i 's/packagekit;//' ${D}${sysconfdir}/mce/10mce.ini
    sed -i 's/fingerprint;//' ${D}${sysconfdir}/mce/10mce.ini
    sed -i 's/buttonbacklight;//' ${D}${sysconfdir}/mce/10mce.ini
}
