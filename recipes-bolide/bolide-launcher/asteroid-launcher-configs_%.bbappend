# Override the emulator compositor configs to:
# 1. Disable libinput so Qt uses evdev handler (which supports abs mode for USB tablet)
# 2. Set correct KMS mode (456x454 instead of 800x800)
FILESEXTRAPATHS:prepend:emulator := "${THISDIR}/${PN}:"
SRC_URI:prepend:emulator = " file://kms.json file://default.conf "

do_install:append:emulator() {
        install -m 0644 ${UNPACKDIR}/kms.json ${D}/var/lib/environment/compositor/
        install -m 0644 ${UNPACKDIR}/default.conf ${D}/var/lib/environment/compositor/
}
