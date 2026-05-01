SUMMARY = "BolideOS Power Manager Daemon"
DESCRIPTION = "Battery health estimation, coulomb counting, power profiles"
HOMEPAGE = "https://github.com/BolideOS/bolide-powerd"
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=84dcc94da3adb52b53ae4fa38fe49e5d"

SRC_URI = "git://github.com/BolideOS/bolide-powerd.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"
PR = "r1"
PV = "1.0+git${SRCPV}"
S = "${WORKDIR}/git"

inherit cmake_qt5 pkgconfig systemd

DEPENDS += "qtbase qtdeclarative qttools-native qtconnectivity sqlite3"
RDEPENDS:${PN} += "connman bluez5 systemd"

SYSTEMD_SERVICE:${PN} = "bolide-powerd.service load-wifi-driver.service"

FILES:${PN} += " \
    /usr/bin/ \
    /usr/lib/systemd/system/ \
    /usr/lib/systemd/system/multi-user.target.wants/ \
    /usr/lib/systemd/system/network.target.wants/ \
    /etc/dbus-1/system.d/ \
    /etc/modprobe.d/ \
    /usr/share/dbus-1/interfaces/ \
    /usr/share/bolide-powerd/ \
"

# CMake installs the service file; add the auto-start symlink
do_install:append() {
    install -d ${D}/usr/lib/systemd/system/multi-user.target.wants/
    ln -sf /usr/lib/systemd/system/bolide-powerd.service \
        ${D}/usr/lib/systemd/system/multi-user.target.wants/bolide-powerd.service
    ln -sf /usr/lib/systemd/system/load-wifi-driver.service \
        ${D}/usr/lib/systemd/system/multi-user.target.wants/load-wifi-driver.service
}
