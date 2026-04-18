SUMMARY = "Roboto Condensed font family (static + variable)"
DESCRIPTION = "Google Roboto Condensed — static weights (Light, Regular, Medium, Bold) \
plus variable font for arbitrary weight interpolation (100-900)."
HOMEPAGE = "https://fonts.google.com/specimen/Roboto+Condensed"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=bf933c06ef59f2ddaaf43c1f09858655"

INHIBIT_DEFAULT_DEPS = "1"
inherit allarch fontcache

SRC_URI = " \
    file://LICENSE \
    file://RobotoCondensed-Light.ttf \
    file://RobotoCondensed-Regular.ttf \
    file://RobotoCondensed-Medium.ttf \
    file://RobotoCondensed-Bold.ttf \
    file://RobotoCondensed-VariableFont_wght.ttf \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${datadir}/fonts/
    install -m 0644 ${UNPACKDIR}/RobotoCondensed-Light.ttf            ${D}${datadir}/fonts/
    install -m 0644 ${UNPACKDIR}/RobotoCondensed-Regular.ttf          ${D}${datadir}/fonts/
    install -m 0644 ${UNPACKDIR}/RobotoCondensed-Medium.ttf           ${D}${datadir}/fonts/
    install -m 0644 ${UNPACKDIR}/RobotoCondensed-Bold.ttf             ${D}${datadir}/fonts/
    install -m 0644 ${UNPACKDIR}/RobotoCondensed-VariableFont_wght.ttf ${D}${datadir}/fonts/
}

FILES:${PN} = "${datadir}/fonts/"
