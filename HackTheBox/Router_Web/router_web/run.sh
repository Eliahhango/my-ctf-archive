#!/bin/sh

EXTRA_ARGS=""
while [ "$1" ]; do
    case "$1" in
    --debug) EXTRA_ARGS="${EXTRA_ARGS} -s"; shift;;
    --) shift; break;;
    *) echo "unknown option: $1" >&2; exit 1;;
    esac
done

exec qemu-system-arm \
    -M versatilepb -kernel zImage -dtb versatile-pb.dtb \
    -drive file=rootfs.ext2,if=scsi,format=raw \
    -append "rootwait root=/dev/sda console=ttyAMA0,115200" \
    -net nic,model=rtl8139 \
    -net user,hostfwd=tcp::1337-:1337,hostfwd=tcp::1338-:1338,hostfwd=tcp::31337-:31337 \
    -nographic -monitor /dev/null  ${EXTRA_ARGS} "$@"
