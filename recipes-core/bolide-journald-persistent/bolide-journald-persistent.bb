SUMMARY = "BolideOS journald configuration: persistent storage for boot diagnostics"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://journald-persistent.conf"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/systemd/journald.conf.d
    install -m 0644 ${UNPACKDIR}/journald-persistent.conf \
        ${D}${sysconfdir}/systemd/journald.conf.d/99-bolide-persistent.conf

    # Pre-create the journal directory so journald uses persistent storage
    install -d ${D}${localstatedir}/log/journal
}

FILES:${PN} = "${sysconfdir}/systemd/journald.conf.d/99-bolide-persistent.conf \
               ${localstatedir}/log/journal"
