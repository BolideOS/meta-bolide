SUMMARY = "BolideOS Settings App"
DESCRIPTION = "Power profiles, battery health UI, airplane mode toggle"
HOMEPAGE = "https://github.com/BolideOS/bolide-settings"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

SRC_URI = "git://github.com/BolideOS/bolide-settings.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

require ../bolide-app.inc

inherit pkgconfig

DEPENDS += "nemo-qml-plugin-systemsettings nemo-qml-plugin-dbus polkit-ceres-rule-reboot"
RDEPENDS:${PN} += "nemo-qml-plugin-systemsettings nemo-qml-plugin-dbus qtmultimedia-qmlplugins libconnman-qt5-qmlplugins polkit-ceres-rule-reboot bolide-powerd"
