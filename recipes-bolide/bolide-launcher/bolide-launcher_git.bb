SUMMARY = "Launcher for AsteroidOS watches with Garmin-style glances"
DESCRIPTION = "Watch face, app launcher, notifications, quick settings, glances panel"
HOMEPAGE = "https://github.com/BolideOS/bolide-launcher"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=1ebbd3e34237af26da5dc08a4e440464"

SRC_URI = "git://github.com/BolideOS/bolide-launcher.git;protocol=https;branch=master"
SRCREV = "${AUTOREV}"
PV = "2.1+git${SRCPV}"
S = "${WORKDIR}/git"

inherit cmake pkgconfig systemd

DEPENDS = "qtbase qtdeclarative qtwayland mapplauncherd lipstick qttools-native"

RDEPENDS:${PN} = " \
    nemo-qml-plugin-configuration-qt5 \
    nemo-qml-plugin-time-qt5 \
    qt5-qpa-hwcomposer-plugin \
    qml-asteroid \
"

SYSTEMD_SERVICE:${PN} = "asteroid-launcher.service"
