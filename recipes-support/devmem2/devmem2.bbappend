FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}/:"

SRC_URI = "file://devmem2.c \
           file://devmem2-fixups-2.patch;apply=yes;striplevel=0"
