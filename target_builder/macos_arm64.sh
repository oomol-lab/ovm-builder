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
	busybox-openrc
	dmesg
	procps
	findmnt
	openssh-server-common-openrc
	blkid
	mount
	mkinitfs
	agetty
	"
# rootfs_name:download_url
rootfs_url="
	alpine-minirootfs-3.20.2-aarch64.tar.gz:https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-minirootfs-3.20.2-aarch64.tar.gz
"
# name:download_url
other_url=""

# file_name:sha1sum
sha1sum="
	alpine-minirootfs-3.20.2-aarch64.tar.gz:62f6c6cdf6a5a1f1d45f4d4458c7e59839997f78
"

# intended_func will be called in make, do not change this function name.
intended_func() {
	# Nothing todo
	echo -n "intended_func in $profile_name"
	# Enable necessary rc-services
	if [[ -n ${rootfs_path} ]]; then
		set -x
		sudo -E proot --rootfs=${rootfs_path} \
			-b /dev:/dev \
			-b /sys:/sys \
			-b /proc:/proc \
			-b /etc/resolv.conf:/etc/resolv.conf \
			-w /root \
			-0 /bin/su -c "
rc-update add acpid default
rc-update add bootmisc boot
rc-update add crond default
rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add hostname boot
rc-update add hwclock boot
rc-update add hwdrivers sysinit
rc-update add killprocs shutdown
rc-update add mdev sysinit
rc-update add modules boot
rc-update add mount-ro shutdown
rc-update add networking boot
rc-update add savecache shutdown
rc-update add seedrng boot
rc-update add swap boot
			"
		set +x
	fi


	# Copy interfaces configure into rootfs, the lo should be autoconfig
	if [[ -n ${rootfs_path} ]]; then
		cd $_cwd_
		cp layers/macos_arm64/etc/network/interfaces ${rootfs_path}/etc/network/interfaces
	fi
}
