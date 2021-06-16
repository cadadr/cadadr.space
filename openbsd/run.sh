#!/bin/sh
# run.sh --- run openbsd vm

# POSIX strict-ish mode, beware eager pipelines!
set -eu
IFS=$'\n\t'

ISO="${ISO-}"
IMG="${IMG-disk.qcow2}"

if [ ! -f "$IMG" ]; then
    echo create "$IMG"
    sh ./mkimg.sh "$IMG"
fi

echo qemu-system-x86_64 \
    -m ${1-256M} -enable-kvm \
    -drive file="$IMG",media=disk,if=virtio \
    -device e1000,netdev=n1 \
    -netdev "user,id=n1,hostname=openbsd-vm,hostfwd=tcp::1965-:1965,hostfwd=tcp::2222-:22" \
    "$([ -n "$ISO" ] && echo -cdrom)" "$([ -n "$ISO" ] && echo "$ISO")" \
    "$([ -n "$ISO" ] && echo -boot once=d)" \
    | sh
