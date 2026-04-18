SUMMARY = "Workout & fitness tracking app for AsteroidOS watches"
DESCRIPTION = "HR zones, GPS tracks, multiple activity types, data screens"
HOMEPAGE = "https://github.com/BolideOS/bolide-fitness"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

SRC_URI = "git://github.com/BolideOS/bolide-fitness.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"
PV = "0.1+git${SRCPV}"
S = "${WORKDIR}/git"

inherit cmake pkgconfig

DEPENDS = "qtbase qtdeclarative"
