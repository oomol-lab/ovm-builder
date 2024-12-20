#!/usr/bin/bash
check_distro() {
	echo "== /etc/lsb-release =="
	grep DISTRIB_ID=Ubuntu /etc/lsb-release && grep DISTRIB_RELEASE=24.04 /etc/lsb-release || {
		echo "Only support build on ubuntu 24.04"
		exit 100
	}
	echo "======================"
}

parse_profile() {
	echo "=== Parse $target_profile ==="

	if [[ ! -f ./target_builder/$target_profile ]]; then
		echo "Error: profile $target_profile not support! "
		exit 100
	fi

	HOST_ARCH=$(uname -p)
	if [[ "${HOST_ARCH}" == 'aarch64' ]]; then
		HOST_ARCH=arm64
	fi
	if [[ "${HOST_ARCH}" == 'x86_64' ]]; then
		HOST_ARCH=amd64
	fi

	echo "HOST_ARCH: $HOST_ARCH"

	TARGET_ARCH=$(echo "${target_profile}" | cut -d '_' -f 2)
	if [[ "${TARGET_ARCH}" == 'aarch64' ]]; then
		TARGET_ARCH=arm64
	fi
	if [[ "${TARGET_ARCH}" == 'x86_64' ]]; then
		TARGET_ARCH=amd64
	fi

	echo TARGET_ARCH: $TARGET_ARCH # only support arm64

	echo "Build ${TARGET_ARCH} on ${HOST_ARCH}"

	if [[ $SKIP_BUILD_PROOT == "true" ]]; then
		echo '$SKIP_BUILD_PROOT == true, skip build proot'
	else
		bash +x ${workspace}/subfunc/build_proot.sh || {
			echo "Error: Build proot failed"
			exit 100
		}
	fi

	if [[ "${HOST_ARCH}" == "${TARGET_ARCH}" ]]; then
		export NATIVE_BUILD=true
		echo "current we do native build..."
	else
		export CROSS_BUILD=true
		echo "current we do cross build, building proot...."
	fi

	bash +x $workspace/target_builder/$target_profile || {
		echo "Error: run $workspace/target_builder/$target_profile failed"
		exit 100
	}
}

usage() {
	cat ./docs/help
}

main() {
	cd "$(dirname $0)"
	if [[ $1 == help ]] || [[ $# -ne 1 ]]; then
		usage
		exit 100
	fi

	export workspace="$(pwd)"
	export output=${workspace}/output

	echo "- workspace: $workspace"
	echo "- output   : ${output}"
	mkdir -p ${output}

	if [[ $# -eq 1 ]]; then
		target_profile=$1
		export target_profile
	fi

	check_distro
	parse_profile
}

main "$@"
