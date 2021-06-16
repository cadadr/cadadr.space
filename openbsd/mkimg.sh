#!/bin/sh
# mkimg.sh --- make disk image

# POSIX strict-ish mode, beware eager pipelines!
set -eu
IFS=$'\n\t'

qemu-img create -f qcow2 "${1-disk.qcow2}" "${2-5G}"
