#! /usr/bin/env bash
set -o pipefail

build_coreos_ignition() {
	cd $_cwd
	cd "$vendor/$package" || {
		echo "Failed to change dir to $vendor/$package"
		exit 100
	}
	go version >/dev/null 2>&1
	ret=$?
	if [[ $ret -ne 0 ]]; then
		echo "go version failed, go compiler not installed or not find in PATH"
		exit 100
	fi
	make && {
		echo "Build ignition done..."
		ls bin/arm64/ignition*
	}

}

pull_source_code() {
	cd $_cwd
	func_name="build_coreos_ignition"
	repo="https://github.com/coreos/ignition"
	vendor=coreos
	package=ignition
	tage="09c99e0305adc1377b87964a39ad2d009aec9b12" # V2.19.0
	github=https://github.com
	repo=$github/$vendor/$package

	if [[ -d  $vendor/$package ]];then
		set -x
		cd $_cwd && cd $vendor/$package
		git checkout .
		git pull
		set +x
		return
	fi

	set -x
	git clone $repo $vendor/$package
	cd $vendor/$package
	git checkout $tage
	ret=$?
	set +x
	if [[ $ret -ne 0 ]]; then
		echo "$func_name: clone $repo failed"
		exit 100
	fi
}

pack_bin() {
	cd $_cwd
	cd $vendor/$package
	cd bin/arm64 || {
		echo "Change dir to  $vendor/$package/bin/arm64 failed"
		exit 100
	}
	rm -rf $vendor_$package.tar
	tar -cvf $vendor_$package.tar *
}

pack() {
	pack_bin
}

build() {
	pull_source_code
	build_coreos_ignition
	pack
}

build
