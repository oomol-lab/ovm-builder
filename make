#!/usr/bin/bash

initialize_var() {
	export LC_ALL=en_US.UTF8
	HOST_MACHINE="$(uname -s)"
	HOST_ARCH="$(uname -p)"

	CONFIG_YAML="./config.yaml"

	pushd . >/dev/null
	SCRIPT_PATH="${BASH_SOURCE[0]}"
	while ([ -h "${SCRIPT_PATH}" ]); do
		cd "$(dirname "${SCRIPT_PATH}")"
		SCRIPT_PATH="$(readlink "$(basename "${SCRIPT_PATH}")")"
	done
	cd "$(dirname "${SCRIPT_PATH}")" >/dev/null
	SCRIPT_PATH="$(pwd)"
	popd >/dev/null

	# set var inited flag
	VAR_INITED=true
}

# First initialize var

_check_return_code_() {
	res="$?"
	if [ "$res" -ne 0 ]; then
		exit 202
	fi
}

_valid_arch_() {
	case ${arch} in
	"x86_64" | "arm64")
		#echo "	!!The string is valid: ${arch}!!"
		;;
	*)
		#echo "	!!The string is not valid: ${arch}!!"
		exit 100
		;;
	esac

}
_valid_plt_() {
	case ${plt} in
	"Windows" | "Linux" | "Drawin")
		#echo "	!!The string is valid: ${plt}!!"
		;;
	*)
		#echo "	!!The string is not valid: ${plt}!!"
		exit 100
		;;
	esac
}

install_tools() {
	echo "------------  ${FUNCNAME[0]} ------------"

	ya_amd64_downloadurl="https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64"
	ya_arm64_downloadurl="https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_arm64"

	cd "${SCRIPT_PATH}"

	if [[ "$HOST_MACHINE" == "Linux" ]] && [[ -f "/usr/bin/dpkg" ]]; then # Debian pr Ubuntu
		DEBS+=(
			"git" "tar" "coreutils" "gzip" "libncurses-dev" "util-linux"
			"bzip2" "rustc" "protobuf-compiler" "busybox" "e2fsprogs"
			"locales-all" "make" "bzip2" "pkg-config" "libseccomp-dev"
			"libgpgme-dev" "cargo" "libarchive-dev" "libtalloc-dev" "uthash-dev"
			"libglib2.0-dev" "libseccomp-dev" "pkg-config" "runc" "iptables" "curl" "openssl"
		)

		if [[ "${HOST_ARCH}" == "arm64" ]] || [[ "${HOST_ARCH}" == "aarch64" ]]; then
			DEBS+=("gcc-x86-64-linux-gnu" "g++-x86-64-linux-gnu")
			wget -c ${ya_arm64_downloadurl} --output-document ./tools/yq_linux_arm64
			_check_return_code_
			chmod +x ./tools/yq_linux_arm64
			_check_return_code_
		fi

		if [[ "${HOST_ARCH}" == "amd64" ]] || [[ "${HOST_ARCH}" == "x86_64" ]]; then
			mkdir -p ./tools
			DEBS+=("gcc-aarch64-linux-gnu" "g++-aarch64-linux-gnu")
			ARCH_AMD64=amd64
			wget -c ${ya_amd64_downloadurl} --output-document ./tools/yq_linux_amd64
			_check_return_code_
			chmod +x ./tools/yq_linux_amd64
			_check_return_code_
			wget -c https://go.dev/dl/go1.22.3.linux-amd64.tar.gz --output-document ./tools/go1.22.3.linux-amd64.tar.gz
			_check_return_code_
			test -f ./tools/go1.22.3.linux-amd64/go/bin/go || {
				mkdir -p ./tools/go1.22.3.linux-amd64/
				tar -xvf ./tools/go1.22.3.linux-amd64.tar.gz -C ./tools/go1.22.3.linux-amd64
			}
			test -f ./tools/go1.22.3.linux-amd64/go/bin/go &&
				export PATH="${SCRIPT_PATH}/tools/:${SCRIPT_PATH}/tools/go1.22.3.linux-amd64/go/bin:${PATH}"
		fi

		for pkg in "${DEBS[@]}"; do
			echo "List installed packages..."
			dpkg -l | grep ${pkg}
			rtvalue=$?
			if [[ "$rtvalue" -eq 0 ]]; then
				continue
			else
				echo "Please install ${pkg}:"
				echo "sudo apt install ${pkg}"
				exit 100
			fi
		done
	else
		echo "Only support Ubuntu x86_64 & arm64"
		exit 100
	fi

	echo "------------ Endof function: ${FUNCNAME[0]} ------------"
	echo ""
}

parseConfigAndCreateDir() {
	echo "------------  ${FUNCNAME[0]} ------------"
	cd "${SCRIPT_PATH}"

	if [[ -f "${CONFIG_YAML}" ]]; then
		echo "- Use CONIFH: ${CONFIG_YAML}"
		TARGET_PLATFORM=$(./tools/yq_linux_"${ARCH_AMD64}" '.TARGET_PLATFORM[]' config.yaml)
		_check_return_code_
		TARGET_ARCH=$(./tools/yq_linux_"${ARCH_AMD64}" '.TARGET_ARCH[]' config.yaml)
		_check_return_code_

		# Clean unexpect strings
		TARGET_PLATFORM=$(echo "${TARGET_PLATFORM}" | xargs | tr -c -d '[:alnum:]_ ')
		TARGET_ARCH=$(echo "${TARGET_ARCH}" | xargs | tr -c -d '[:alnum:]_ ')

		for plt in ${TARGET_PLATFORM}; do
			_valid_plt_ # Valid target platform
			for arch in ${TARGET_ARCH}; do
				_valid_arch_ # Valid target arch
			done
		done

		echo "- TARGET_PLATFORM: ${TARGET_PLATFORM}"
		echo "- TARGER_ARCH: ${TARGET_ARCH}"

		OVMCORE_PLATFORM=""
		for plt in ${TARGET_PLATFORM}; do
			for arch in ${TARGET_ARCH}; do
				OVMCORE_PLATFORM="$OVMCORE_PLATFORM $plt-$arch"
			done
		done
		#echo "- Targets List: $OVMCORE_PLATFORM"
	fi
	echo "------------ Endof function: ${FUNCNAME[0]} ------------"
	echo ""

}

build_proot() {
	local proot_src="${SCRIPT_PATH}/tools/proot_src"
	local repo="https://github.com/proot-me/proot"
	test -d "${proot_src}" || git clone "${repo}" "${proot_src}"
	_check_return_code_
	cd "${proot_src}"
	make -C src loader.elf build.h
	_check_return_code_
	make -C src proot care
	_check_return_code_

	if [[ -f ${proot_src}/src/proot ]]; then
		cp "${proot_src}/src/proot" "${SCRIPT_PATH}/tools/"
	fi
}

#
# For now only support target: WSL2
#
build_each_platform() {
	echo "------------  ${FUNCNAME[0]} ------------"
	cd "${SCRIPT_PATH}"
	echo "Build targer: ${OVMCORE_PLATFORM}"
	for target in ${OVMCORE_PLATFORM}; do
		builder="./target_builder/build_${target}_rootfs"
		test -f "${builder}" &&
			HOST_ARCH="${HOST_ARCH}" \
				HOST_MACHINE="${HOST_MACHINE}" \
				TARGET="${target}" \
				CALLER_ID="d9b59105e7569a37713aeadb493ca01a3779747f" \
				WORKDIR="$SCRIPT_PATH" \
				PATH=${PATH} \
				PS4='Line ${LINENO}: ' \
				bash +x "./target_builder/build_${target}_rootfs"
	done
	echo "------------ Endof function: ${FUNCNAME[0]} ------------"
	echo ""
}

main() {
	initialize_var
	cd "${SCRIPT_PATH}"
	install_tools
	build_proot
	parseConfigAndCreateDir
	build_each_platform
}

main
