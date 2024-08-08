# Profile of macos_arm64

# Do not change this plz
rootfs_type="alpine_based"

profile_name="macos_arm64"
layer="layers/${profile_name}"

# one package one line
preinstalled_packages="
	bash
	openrc
	podman
	e2fsprogs
	busybox-mdev-openrc
	dmesg
	procps
	findmnt
	blkid
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


# intended_func will be called in make, do not change this function name.
intended_func() {
	# Nothing todo
	echo -n ""
}
