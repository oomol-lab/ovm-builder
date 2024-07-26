# Profile of amd64_wsl

# Do not change this plz
rootfs_type=alpine_based

# one package one line
preinstalled_packages="
	bash
	openrc
	podman
	busybox-mdev-openrc
	dmesg
	mount
	"
# rootfs_name:download_url
rootfs_url="
	alpine-minirootfs-3.20.2-x86_64.tar.gz:https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.2-x86_64.tar.gz
"
# name:download_url
other_url=""

# file_name:sha1sum
sha1sum="
	alpine-minirootfs-3.20.2-x86_64.tar.gz:9bbb7008afafb1579ed8f10ee3bdbddccc4275e9
"
