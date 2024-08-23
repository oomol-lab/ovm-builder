#! /bin/bash
set -o pipefail
PS4='Line ${LINENO}: '

http_proxy=${http_proxy}
https_proxy=${https_proxy}
ftp_proxy=${ftp_proxy}

# export kernel_src
pull_ksrc() {
	set -ex
	cd "$out_dir" || {
		echo "Error: can not change dir to ${out_dir}"
		exit 100
	}
	set +ex
	if [[ ${kernel_version} = "next" ]] && [[ -d "${out_dir}/linux-next" ]]; then
		set -ex
		cd "${out_dir}/linux-next" || {
			echo "Error: can not change dir to ${out_dir}/linux-next"
			exit 100
		}
		kernel_src=$(pwd)
		git checkout .
		set +ex

		if [[ $PULL_SOURCE_BUILD = true ]]; then
			set -xe
			git config pull.rebase true
			git pull
			set +ex
		fi

		set -xe
		git checkout master
		set +xe
	elif [[ ${kernel_version} = "next" ]] && [[ ! -d "${out_dir}/linux-next" ]]; then
		set -ex
		cd "$out_dir" || {
			echo "Error: can not change dir to ${out_dir}"
			exit 100
		}
		git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git linux-next
		cd "$out_dir/linux-next"
		kernel_src=$(pwd)
		set +ex
	elif [[ -n ${kernel_version} ]]; then
		set -ex
		cd "$out_dir" || {
			echo "Error: can not change dir to ${out_dir}"
			exit 100
		}
		wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${kernel_version}.tar.sign" >/dev/null 2>&1
		wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${kernel_version}.tar.xz" >/dev/null 2>&1
		tar -xvf linux-"${kernel_version}".tar.xz >/dev/null
		cd "$out_dir/linux-${kernel_version}"
		kernel_src=$(pwd)
		set +ex
	fi

	set -ex
	dts_picked="${kernel_src}/arch/${arch_machine}/boot/dts/$board_picked.dts"
	set +ex
	if [[ ! -f "${dts_picked}" ]]; then
		echo "Error: Board not find"
		echo "not exist: $dts_picked"
		exit 100
	fi
}

clean_output() {
	if [[ ${CLEAN_BUILD} = true ]]; then
		set -xe
		rm -rf "${compiled_output_dir}"
		set +xe
	fi
}

make_config() {
	set -ex
	cd "$kernel_src" || {
		echo "Error: can not change dir to ${out_dir}"
		exit 100
	}
	cat "${kernel_config}" arch/arm64/configs/defconfig kernel/configs/kvm_guest.config | grep -v '#' | sort | uniq >/tmp/config_merge
	cat /tmp/config_merge >arch/arm64/configs/defconfig
	make LLVM=1 O="${compiled_output_dir}" defconfig -j "$n_proc"
	set +ex

	if [[ "${MENU_CONFIG}" = true ]]; then
		set -ex
		make LLVM=1 O="${compiled_output_dir}" menuconfig
		set +ex
	fi
	rm -rf /tmp/config_merge
}

make_build() {
	http_proxy=""
	https_proxy=""
	all_proxy=""
	ftp_proxy=""
	set -ex
	cd "$kernel_src" || {
		echo "Error: can not change dir to ${out_dir}"
		exit 100
	}
	bear -- make LLVM=1 O="${compiled_output_dir}" -j "$n_proc"
	make LLVM=1 O="${compiled_output_dir}" -j "$n_proc" Image.gz
	install_dest="${compiled_output_dir}/kernel_package_$board_picked"
	INSTALL_MOD_PATH="${install_dest}" \
		INSTALL_HDR_PATH="${install_dest}" \
		make LLVM=1 \
		O="${compiled_output_dir}" \
		-j "$n_proc" \
		modules_install \
		vdso_install \
		headers_install
	set +ex
}

pack_kernel() {
	set -ex
	cd "${compiled_output_dir}"
	dtb_picked="arch/${arch_machine}/boot/dts/$board_picked.dtb"
	cp System.map .config "$dtb_picked" "arch/$arch_machine/boot/Image.gz" "${install_dest}"
	cp -rf usr/include 		   	 "${install_dest}/include"
	cp "${_cwd}/install_kernel.sh" 		 "${install_dest}"
	cp "${kernel_src}/compile_commands.json" "${install_dest}"
	set +ex

	find "${install_dest}" -name "*.ko" | while read -r ko_file; do
		strip --strip-unneeded "$ko_file"
	done

	set -ex
	tar -Jcvf "${vendor}_${hardware}_${kernel_version}.tar.xz" "kernel_package_${vendor}/${hardware}" >/dev/null
	cp "${vendor}_${hardware}_${kernel_version}.tar.xz" "${HOME}/"
	set +ex
}

useage() {
	echo '
# Envs:
# CLEAN_BUILD = true 	      : clean all output and build
# PULL_SOURCE_BUILD = true    : pull source code before build, all changes will be droped
# MENU_CONFIG = true 	      : before build, make menuconfig
# N_PROC = number of cpu core : make -j $n_proc

# Args:
# arg[1] = $kernel_version
# arg[2] = $board_picked
# arg[3] = $kernel_config
# arg[4] = $out_dir
'

}

# Envs:
# CLEAN_BUILD = true 	      : clean all output and build
# PULL_SOURCE_BUILD = true    : pull source code before build, all changes will be droped
# MENU_CONFIG = true 	      : before build, make menuconfig
# N_PROC = number of cpu core : make -j $n_proc

# Args:
# arg[1] = $kernel_version
# arg[2] = $board_picked
# arg[3] = $kernel_config
# arg[4] = $out_dir

main() {
	argc=$#
	if [[ $argc -eq 0 ]]; then
		useage
		exit
	fi

	_cwd=$(pwd)
	set -x
	script_name=$(basename $0)
	kernel_version=$1
	board_picked=$2
	kernel_config=$3
	out_dir=${4}/${script_name}
	set +ex

	if [[ ! -f ${kernel_config} ]]; then
		echo "Error: kernel config not exist"
		exit 100
	else
		file ${kernel_config} | grep 'ASCII text' >/dev/null 2>&1
		ret=$?
		test $ret -eq 0 && {
			echo "${kernel_config} is a ASCII text" >/dev/null 2>&1
		} || {
			echo "${kernel_config} not a ASCII text"
			exit 100
		}
	fi

	export vendor=$(dirname "$board_picked")    # rockchip
	export hardware=$(basename "$board_picked") # rk3399-evb

	set -ex
	mkdir -p "${out_dir}"
	set +ex

	# get host machine arch
	arch_machine=$(uname -m)
	if [[ $arch_machine = aarch64 ]] || [[ $arch_machine = arm64 ]]; then
		arch_machine=arm64
	fi

	compiled_output_dir="${out_dir}/compiled_output_dir_${arch_machine}"

	# get cpu core for make -j $n_proc
	if [[ -n ${N_PROC} ]]; then
		n_proc=${N_PROC}
	else
		n_proc=2
	fi

	clean_output
	pull_ksrc
	make_config
	make_build
	pack_kernel

}

main "$@"
