SUMMARY = "Power management daemon for AsteroidOS watches"
DESCRIPTION = "Battery health estimation, coulomb counting, power profiles"
HOMEPAGE = "https://github.com/BolideOS/bolide-powerd"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

SRC_URI = "git://github.com/BolideOS/bolide-powerd.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"
S = "${WORKDIR}/git"

inherit cmake pkgconfig systemd

DEPENDS = "qtbase mapplauncherd"

SYSTEMD_SERVICE:${PN} = "bolide-powerd.service"
