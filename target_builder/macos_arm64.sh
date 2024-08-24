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
# Build kernel for macos_arm64 using custom kernel config
kernel_builder() {
	echo "Build kernel for $profile_name"
	if [[ ! -n ${workspace} ]]; then
		echo 'Error: env ${workspace} empty'
		exit 100
	else
		cd $workspace
	fi
	if [[ ! -n ${output} ]]; then
		echo 'Error: env ${output} empty'
		exit 100
	fi

	set -x
	kernel_config="${workspace}/layers/macos_arm64/etc/buildinfo/kernel_config"
	set +x
	if [[ -f ${kernel_config} ]]; then
		set -x
		CLEAN_BUILD=false \
			PULL_SOURCE_BUILD=true \
			N_PROC=16 \
			WORKSPACE=${workspace} \
			./subfunc/build_kernel.sh \
			next \
			rockchip/rk3399-eaidk-610 ${kernel_config} ${output}
			set +x
	else
		echo 'Error: env ${kernel_config}'
		exit 100
	fi
}

# intended_func will be called in make, do not change this function name.
intended_func() {
	# Nothing todo
	echo -n "intended_func in $profile_name"
	if [[ -f ${proot_src}/src/proot ]];then
		echo -n ""
	else
		echo 'Error: ${proot_src}/src/proot not exist'
		exit 100
	fi
	# Enable necessary rc-services
	if [[ -n ${rootfs_path} ]]; then
		set -x
		sudo -E ${proot_src}/src/proot --rootfs=${rootfs_path} \
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
	else
		echo 'env ${rootfs_path} empty'
		exit 100
	fi

	# Copy interfaces configure into rootfs, the lo should be autoconfig
	if [[ -n ${rootfs_path} ]]; then
		cd $_cwd_
		cp layers/macos_arm64/etc/network/interfaces ${rootfs_path}/etc/network/interfaces
	fi
}
