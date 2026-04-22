SUMMARY = "BolideOS Power Configuration"
DESCRIPTION = "Boot-time power optimizations: CPU governor, autosleep, \
LPM deep sleep, CPU offlining, and journald limits. \
Applies to all watch targets."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

SRC_URI = " \
    file://power-optimize.sh \
    file://bolide-power-optimize.service \
    file://00-power.conf \
    file://99-power.conf \
"

inherit systemd

S = "${WORKDIR}/sources"
UNPACKDIR = "${S}"

SYSTEMD_SERVICE:${PN} = "bolide-power-optimize.service"

do_install() {
    # Power optimization script
    install -d ${D}${libexecdir}
    install -m 0755 ${UNPACKDIR}/power-optimize.sh ${D}${libexecdir}/bolide-power-optimize

    # Systemd service
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/bolide-power-optimize.service ${D}${systemd_system_unitdir}/

    # Journald drop-in for power savings
    install -d ${D}${sysconfdir}/systemd/journald.conf.d
    install -m 0644 ${UNPACKDIR}/00-power.conf ${D}${sysconfdir}/systemd/journald.conf.d/

    # Mask services that waste power on watches
    # NOTE: Do NOT mask iptables.service or systemd-networkd.service here —
    # their package postinstall scripts need to run during image build.
    # Those are masked at runtime by the power-optimize script instead.
    install -d ${D}${sysconfdir}/systemd/system
    for svc in \
        ofono.service \
        getty@tty1.service \
        serial-getty@ttyHSL0.service \
        serial-getty@ttyMSM0.service \
        serial-getty@ttyS0.service \
        polkit.service \
        profiled.service \
        ngfd.service \
        obexd.service \
        mpris-proxy.service \
        systemd-tmpfiles-clean.timer \
    ; do
        ln -sf /dev/null ${D}${sysconfdir}/systemd/system/$svc
    done

    # Sysctl drop-in for VM power tuning
    install -d ${D}${sysconfdir}/sysctl.d
    install -m 0644 ${UNPACKDIR}/99-power.conf ${D}${sysconfdir}/sysctl.d/
}

FILES:${PN} = " \
    ${libexecdir}/bolide-power-optimize \
    ${systemd_system_unitdir}/bolide-power-optimize.service \
    ${sysconfdir}/systemd/journald.conf.d/00-power.conf \
    ${sysconfdir}/sysctl.d/99-power.conf \
    ${sysconfdir}/systemd/system/ \
"

RDEPENDS:${PN} = "systemd"
