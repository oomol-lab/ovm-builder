# Profile of amd64_wsl

# Do not change this plz
rootfs_type="alpine_based"

profile_name="amd64_wsl2"
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

# WSL2 no need build kernel
kernel_builder(){
	echo "Skip build kernel in ${profile_name}"
	exit 0
}


# intended_func will be called in make, do not change this function name.
intended_func() {
	if [[ -n ${_cwd_} ]]; then
		cd "${_cwd_}" || {
			echo "Error: can not change workdir, stoped"
			exit 100
		}
	else
		echo "Error: can not change workdir, stoped"
		exit 100
	fi

	if [[ ! -d "${layer}" ]]; then
		echo "Error: ${layer} not exist, stoped"
		exit 100
	fi

	if [[ -n ${rootfs_path} ]]; then
		echo "($basename $0): Copy amd64_wsl2 layer"
		set -xe
		cp -rf ${layer}/*  ${rootfs_path}
		set +xe
	else
		echo "Error: Env rootfs_path not defined by called script $0, stoped"
		exit 100
	fi
}
