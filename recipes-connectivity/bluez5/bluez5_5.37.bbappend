NOINST_TOOLS_READLINE_append = " \
    tools/btmgmt \
"

NOINST_TOOLS_EXPERIMENTAL_remove = " \
    tools/btmgmt \
"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " \
	file://variscite-bt \
	file://variscite-bt.service \
	file://variscite-bt.conf \
	file://audio.conf \
"

do_install_append() {
	install -d ${D}${sysconfdir}/bluetooth
	install -m 0644 ${WORKDIR}/variscite-bt.conf ${D}${sysconfdir}/bluetooth
	install -m 0644 ${WORKDIR}/audio.conf ${D}/${sysconfdir}/bluetooth

	if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
		install -d ${D}${systemd_unitdir}/system
		install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
		install -m 0644 ${WORKDIR}/variscite-bt.service ${D}${systemd_unitdir}/system
		install -m 0755 ${WORKDIR}/variscite-bt ${D}${sysconfdir}/bluetooth
	else
		install -m 0755 ${WORKDIR}/variscite-bt ${D}${sysconfdir}/init.d
	fi
}
