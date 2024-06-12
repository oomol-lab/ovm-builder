UBT_ROOTFS=
proot --root-id -R "${UBT_ROOTFS}" apt update
proot --root-id -R "${UBT_ROOTFS}" apt install apt-utils
proot --root-id -R "${UBT_ROOTFS}" apt install iptables
libs=$(proot --root-id -R "${UBT_ROOTFS}" ldd /usr/sbin/iptables)
