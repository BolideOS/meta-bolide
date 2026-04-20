SUMMARY = "BolideOS Launcher and Wayland compositor"
DESCRIPTION = "Watch face, app launcher, notifications, quick settings"
HOMEPAGE = "https://github.com/BolideOS/bolide-launcher"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://src/qml/MainScreen.qml;beginline=1;endline=29;md5=dc9980ea8441655e2d7b323a30b7172d"

SRC_URI = "git://github.com/BolideOS/bolide-launcher.git;protocol=https;branch=master \
    file://bolide-launcher.service \
    file://bolide-launcher-precondition \
    file://lipstick.conf"
SRCREV = "${AUTOREV}"
PR = "r1"
PV = "2.1+git${SRCPV}"
S = "${WORKDIR}/git"

inherit cmake_qt5 pkgconfig

DEPENDS += "qml-asteroid lipstick qttools-native timed"
RDEPENDS:${PN} += "qtdeclarative-qmlplugins qml-asteroid mce-qt5 qtwayland-plugins \
    nemo-qml-plugin-time nemo-qml-plugin-configuration \
    asteroid-wallpapers asteroid-launcher-configs"

FILES:${PN} += "/usr/share/bolide-launcher/ /usr/lib/systemd/user/ /usr/share/translations/ \
    /usr/lib/systemd/user/default.target.wants/ /usr/bin/ /usr/share/lipstick/"

# Downgrade QML import versions for Qt 5.12 compatibility
do_configure:prepend() {
    find ${S} -name "*.qml" | xargs sed -i \
        -e 's/import QtQuick 2\.\(1[3-9]\|[2-9][0-9]\)/import QtQuick 2.12/g' \
        -e 's/import QtGraphicalEffects 1\.[0-9]*/import QtGraphicalEffects 1.0/g' \
        -e 's/import QtQuick\.Shapes 1\.[0-9]*/import QtQuick.Shapes 1.0/g' \
        2>/dev/null || true
}

do_install:append() {
    lrelease -idbased ${S}/i18n/bolide-launcher.*.ts
    install -d ${D}/usr/share/translations/
    cp ${S}/i18n/bolide-launcher.*.qm ${D}/usr/share/translations/

    install -d ${D}/usr/lib/systemd/user/
    install -d ${D}/usr/lib/systemd/user/default.target.wants/
    install -d ${D}/usr/bin/
    install -m 0755 ${UNPACKDIR}/bolide-launcher-precondition ${D}/usr/bin
    install -D -m 644 ${UNPACKDIR}/bolide-launcher.service ${D}/usr/lib/systemd/user/
    if [ ! -f ${D}/usr/lib/systemd/user/default.target.wants/bolide-launcher.service ]; then
        ln -s /usr/lib/systemd/user/bolide-launcher.service \
            ${D}/usr/lib/systemd/user/default.target.wants/bolide-launcher.service
    fi

    # Default app launcher ordering (bolide-fitness first)
    install -d ${D}/usr/share/lipstick/
    install -m 0644 ${UNPACKDIR}/lipstick.conf ${D}/usr/share/lipstick/lipstick.conf
}
