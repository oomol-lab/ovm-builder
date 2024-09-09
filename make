#!/usr/bin/bash
parse_profile() {
	export LC_ALL=en_US.UTF8
	# Only support Linux
	HOST_MACHINE="$(uname -s)"
	HOST_ARCH="$(uname -p)"
	profile_dir="$_cwd_/target_builder/"
	if [[ ! -f ${profile_dir}/${target_profile}.sh ]];then
		echo "Error: $target_profile not support! "
		echo "${profile_dir}/${target_profile}.sh not exist or wrong !"
		exit 100
	fi
	TARGET_ARCH=$(echo "${target_profile}" | cut -d '_' -f 2)
	# aarch64 and arm64 are same cpu arch
	if [[ "${HOST_ARCH}" = 'aarch64' ]];then
		HOST_ARCH=arm64
	fi

	if [[ ! "${HOST_ARCH}" = "${TARGET_ARCH}" ]];then
		echo "Error: HOST_ARCH must equal TARGET_ARCH"
		echo "Your HOST_ARCH: ${HOST_ARCH}"
		echo "Your TARGET_ARCH: ${TARGET_ARCH}"
		exit 100
	fi
	set +x
	source "$profile_dir/${target_profile}.sh"
	is_profile_loaded=true
	set -x
}

# Must called from func install_hosts_tools
_build_proot() {
	if [[ ! $callid = "T0Rrek1nbz0K" ]]; then
		exit 100
	fi
	proot_src=$output/proot_src

	if [[ -d $proot_src ]]; then
		set -xe
		cd $proot_src
		make -C src loader.elf build.h
		make -C src proot
		set +xe
	else
		set -xe
		git clone --depth 1 https://github.com/proot-me/proot $proot_src
		cd $proot_src
		make -C src loader.elf build.h
		make -C src proot
		set +xe
	fi
	PATH="$proot_src/src:$PATH"
	set -xe
	sudo -E ${proot_src}/src/proot --version
	cd $_cwd_
	set +xe
}

profile_funcs() {
	if [[ ${is_profile_loaded} = true ]]; then
		cd $_cwd_
		kernel_builder
		intended_func
		make_rootfs_disk
	fi
}

install_hosts_tools() {
	set -x
	sudo apt install libarchive-dev libtalloc-dev uthash-dev gcc make git wget tar xz-utils
	set +x
	callid="T0Rrek1nbz0K" _build_proot
}
usage() {
	echo '
# Envs:
#   NULL
# Args:
#   arg[1] [amd64_wsl,arm64_macos]
#
# example: ./make amd64_wsl2
'
}

# export rootfs_path
bootstrap_alpine() {
	set -xe
	# Note the workdir changed to $output
	cd $output
	rootfs_name=$(echo ${rootfs_url} | cut -d ':' -f1)
	rootfs_url=$(echo ${rootfs_url} | cut -d ':' -f2-)
	wget -c $rootfs_url --output-document=$rootfs_name
	sudo rm -rf rootfs_extracted
	mkdir rootfs_extracted
	tar -xvf $rootfs_name -C ./rootfs_extracted >/dev/null 2>&1
	cd rootfs_extracted
	rootfs_path=$(pwd)
	export rootfs_path
	# Note the workdir changed to $_cwd
	cd $_cwd_
	set +xe
}

install_package_into_rootfs() {
	cd $_cwd_
	pkgs=$(echo $preinstalled_packages | xargs)
	set -xe
	sudo -E ${proot_src}/src/proot --rootfs=${rootfs_path} \
		-b /dev:/dev \
		-b /sys:/sys \
		-b /proc:/proc \
		-b /etc/resolv.conf:/etc/resolv.conf \
		-w /root \
		-0 /bin/su -c "sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories"
	sudo -E ${proot_src}/src/proot --rootfs=${rootfs_path} \
		-b /dev:/dev \
		-b /sys:/sys \
		-b /proc:/proc \
		-b /etc/resolv.conf:/etc/resolv.conf \
		-w /root \
		-0 /bin/su -c "apk update ; apk add $pkgs"
	set -xe
}

pack_rootfs() {
	cd $_cwd_

	# Note we changed work dir to $rootfs_path
	cd $rootfs_path
	file_list="$(ls . | xargs)"

	set -xe
	sudo -E tar --zstd -cvf "/tmp/rootfs_extracted.tar.zst" $file_list >/dev/null
#	sudo -E tar -Jcvf "/tmp/rootfs_extracted.tar.xz" $file_list >/dev/null
	cp /tmp/rootfs_extracted.tar.zst $output
#	cp /tmp/rootfs_extracted.tar.xz $output
	set +xe

	echo " --- $target_profile ---"
	echo "rootfs: $output/rootfs_extracted.tar.zst"
	echo "rootfs: $output/rootfs_extracted.tar.xz"
	echo ""
}

main() {
	# Work dir
	_cwd_=$(dirname $0)
	cd $_cwd_
	_cwd_=$(pwd)
	# export $workspace to all functions
	# TODO: replace _cwd_ to workspace
	export workspace=${_cwd_}
	output=${_cwd_}/output
	mkdir -p ${output}

	if [[ $# -eq 1 ]]; then
		target_profile=$1
	else
		usage
		exit 100
	fi
	parse_profile
	install_hosts_tools
	bootstrap_alpine
	install_package_into_rootfs
	profile_funcs
	pack_rootfs
}

main "$@"
