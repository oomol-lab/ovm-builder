#!/usr/bin/bash
# Get current work directory
script="$(realpath "$0")"
script_path="$(dirname "$script")"
cd "${script_path}" || {
	echo "initialize work dir failed"
	exit 1
}

workspace="$script_path"

check_distro() {
	lsb_file="/etc/lsb-release"
	grep "DISTRIB_ID=Ubuntu" "$lsb_file" && grep "DISTRIB_RELEASE=24.04" "$lsb_file" || {
		echo "Only support build on ubuntu 24.04"
		exit 100
	}
}

parse_profile() {
	target_profile="$workspace/target_builder/$target_profile"
	if [[ -f "$target_profile" ]]; then
		echo "Target profile: $target_profile"
	else
		echo "Error: $target_profile not find! "
		exit 100
	fi

	# normalization the host arch field
	HOST_ARCH="$(uname -p)"
	if [[ "${HOST_ARCH}" == 'aarch64' ]]; then
		HOST_ARCH=arm64
	fi
	if [[ "${HOST_ARCH}" == 'x86_64' ]]; then
		HOST_ARCH=amd64
	fi

	echo "HOST_ARCH: $HOST_ARCH"

	# normalization the target arch field
	TARGET_ARCH="$(basename "${target_profile}" | cut -d '_' -f 2)"
	if [[ "${TARGET_ARCH}" == 'aarch64' ]]; then
		TARGET_ARCH=arm64
	fi
	if [[ "${TARGET_ARCH}" == 'x86_64' ]]; then
		TARGET_ARCH=amd64
	fi

	echo TARGET_ARCH: "$TARGET_ARCH" # only support arm64

	# Build Proot
	if [[ "$SKIP_BUILD_PROOT" == "true" ]]; then
		echo 'env SKIP_BUILD_PROOT == true, skip build proot'
	else
		workspace="$workspace" output="$output" bash "${workspace}/subfunc/build_proot.sh" || {
			echo "Error: Build proot failed"
			exit 100
		}
	fi

	# Install qemu
	if [[ "$SKIP_INSTALL_QEMU" == "true" ]]; then
		echo "env SKIP_INSTALL_QEMU set true, skip install qemu"
	else
		output="$output" workspace="$workspace" bash +x "${workspace}/subfunc/install_qemu.sh" || {
			echo "Error: Install qemu failed"
			exit 100
		}
	fi

	if [[ "${HOST_ARCH}" == "${TARGET_ARCH}" ]]; then
		export BUILD_TYPE=native
		echo "current we do native build"
	else
		export BUILD_TYPE=cross
		echo "current we do cross build"
	fi

	workspace="$workspace" output="$output" target_profile="$target_profile" bash "$target_profile" || {
		echo "Error: run $target_profile failed"
		exit 100
	}
}

usage() {
	help_file="docs/help"
	cat "$help_file"
}

main() {
	SKIP_BUILD_PROOT="${SKIP_BUILD_PROOT:-false}"
	SKIP_APT_GET_INSTALL="${SKIP_APT_GET_INSTALL:-false}"
	VM_PROVIDER="${VM_PROVIDER:-applehv}"
	export SKIP_BUILD_PROOT
	export SKIP_APT_GET_INSTALL
	export VM_PROVIDER

	check_distro

	if [[ "$1" == help ]] || [[ "$#" -ne 1 ]]; then
		usage
		exit 0
	fi

	output="${workspace}/output"
	mkdir -p "${output}"
	echo "==> workspace: $workspace"
	echo "==> output   : ${output}"

	target_profile="$1"
	parse_profile
}

main "$@"
