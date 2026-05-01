SUMMARY = "BolideOS Shell (combined launcher + settings)"
DESCRIPTION = "Single-process Wayland compositor with inline settings for faster app switching"
LICENSE = "BSD-3-Clause & GPL-3.0-only"
LIC_FILES_CHKSUM = "file://src/main.cpp;beginline=1;endline=6;md5=d889dcd7b86baa3e9f42aa438c9c076b"

SRC_URI = "file://bolide-shell.service \
    file://bolide-launcher-precondition \
    file://lipstick.conf"
PR = "r1"
PV = "0.1.0"

inherit cmake_qt5 pkgconfig

# Combined dependencies from both launcher and settings
DEPENDS += "qml-asteroid lipstick qttools-native timed \
    nemo-qml-plugin-systemsettings nemo-qml-plugin-dbus"

RDEPENDS:${PN} += "qtdeclarative-qmlplugins qml-asteroid mce-qt5 qtwayland-plugins \
    nemo-qml-plugin-time nemo-qml-plugin-configuration \
    asteroid-wallpapers asteroid-launcher-configs \
    nemo-qml-plugin-systemsettings nemo-qml-plugin-dbus \
    qtmultimedia-qmlplugins libconnman-qt5-qmlplugins \
    polkit-ceres-rule-reboot bolide-powerd"

# Conflict with standalone launcher and settings
RCONFLICTS:${PN} = "bolide-launcher bolide-settings"
RREPLACES:${PN} = "bolide-launcher bolide-settings"
RPROVIDES:${PN} = "bolide-launcher bolide-settings"

# Downgrade QML import versions for Qt 5.12 compatibility
# Must also cover launcher and settings QML files referenced via QRC
do_configure:prepend() {
    for dir in ${S} ; do
        if [ -d "$dir" ]; then
            find "$dir" -name "*.qml" | xargs sed -i \
                -e 's/import QtQuick 2\.\(1[3-9]\|[2-9][0-9]\)/import QtQuick 2.12/g' \
                -e 's/import QtGraphicalEffects 1\.[0-9]*/import QtGraphicalEffects 1.0/g' \
                -e 's/import QtQuick\.Shapes 1\.[0-9]*/import QtQuick.Shapes 1.0/g' \
                2>/dev/null || true
        fi
    done
}

do_install:append() {
    # Install launcher translations
    if ls ${S}/i18n/bolide-launcher.*.ts 1>/dev/null 2>&1; then
        lrelease -idbased ${S}/i18n/bolide-launcher.*.ts
        install -d ${D}/usr/share/translations/
        cp ${S}/i18n/bolide-launcher.*.qm ${D}/usr/share/translations/
    fi

    # Install settings translations
    if ls ${S}/i18n/bolide-settings.*.ts 1>/dev/null 2>&1; then
        lrelease -idbased ${S}/i18n/bolide-settings.*.ts
        cp ${S}/i18n/bolide-settings.*.qm ${D}/usr/share/translations/
    fi

    # Install service file
    install -d ${D}/usr/lib/systemd/user/
    install -d ${D}/usr/lib/systemd/user/default.target.wants/
    install -D -m 644 ${UNPACKDIR}/bolide-shell.service ${D}/usr/lib/systemd/user/
    ln -sf /usr/lib/systemd/user/bolide-shell.service \
        ${D}/usr/lib/systemd/user/default.target.wants/bolide-shell.service

    # Install precondition and lipstick config (from launcher)
    install -d ${D}/usr/bin/
    install -m 0755 ${UNPACKDIR}/bolide-launcher-precondition ${D}/usr/bin/

    install -d ${D}/usr/share/lipstick/
    install -m 0644 ${UNPACKDIR}/lipstick.conf ${D}/usr/share/lipstick/lipstick.conf

    # Install compositor environment snippet (QML import path)
    install -d ${D}/var/lib/environment/compositor/
    echo 'QML2_IMPORT_PATH=/usr/lib/qt5/qml' > ${D}/var/lib/environment/compositor/bolide.conf

    # Install watchfaces and applauncher QML files
    install -d ${D}/usr/share/bolide-launcher/watchfaces/
    install -d ${D}/usr/share/bolide-launcher/applauncher/
    if [ -d "${S}/src/watchfaces" ]; then
        install -m 0644 ${S}/src/watchfaces/*.qml ${D}/usr/share/bolide-launcher/watchfaces/
    fi
    if [ -d "${S}/src/applauncher" ]; then
        install -m 0644 ${S}/src/applauncher/*.qml ${D}/usr/share/bolide-launcher/applauncher/
    fi
}

FILES:${PN} += "/usr/share/bolide-launcher/ /usr/lib/systemd/user/ \
    /usr/share/translations/ /usr/lib/systemd/user/default.target.wants/ \
    /usr/bin/ /usr/share/lipstick/ /var/lib/environment/compositor/"
