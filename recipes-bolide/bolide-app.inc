# Shared include for BolideOS app recipes
# Similar to asteroid-app.inc but for bolide-* packages

PR = "r1"
S = "${WORKDIR}/git"
inherit cmake_qt5

# Downgrade QML import versions to match Qt 5.12
do_configure:prepend() {
    find ${S} -name "*.qml" | xargs sed -i \
        -e 's/import QtQuick 2\.\(1[3-9]\|[2-9][0-9]\)/import QtQuick 2.12/g' \
        -e 's/import QtGraphicalEffects 1\.[0-9]*/import QtGraphicalEffects 1.0/g' \
        -e 's/import QtQuick\.Shapes 1\.[0-9]*/import QtQuick.Shapes 1.0/g' \
        2>/dev/null || true
}

DEPENDS += "qml-asteroid asteroid-generate-desktop-native qttools-native qtdeclarative-native"
FILES:${PN} += "/usr/share/translations/ ${libdir}/${PN}.so"
