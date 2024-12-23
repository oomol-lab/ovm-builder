#! /usr/bin/env bash
x86_64_loader_ld="ld-linux-x86-64.so.2"
arm64_loader_ld="ld-linux-aarch64.so.1"

host_arch=$(uname -m)
if [[ $host_arch == aarch64 ]] || [[ $host_arch == arm64 ]]; then
	host_arch=arm64
	ld_loader="$arm64_loader_ld"
fi

if [[ $host_arch == amd64 ]] || [[ $host_arch == x86_64 ]]; then
	host_arch=x86_64
	ld_loader="$x86_64_loader_ld"
fi

check_envs() {
	test -n $output || {
		echo 'Env: output failed'
		exit 100
	}

	test -n $workspace || {
		echo 'Env: workspace failed'
		exit 100
	}

	test -n $host_arch || {
		echo 'Env: host_arch failed'
		exit 100
	}
}

download_qemu() {
	if [[ "$(uname -s)" == "Linux" ]]; then
		echo "INFO: Download qemu_bin-linux-$host_arch.tar.xz"
		set -xe
		sudo -E apt -y install xz-utils tar binutils zstd
		mkdir -p "$output" && cd "$output"
		wget "https://github.com/oomol/builded/releases/download/v1.6/qemu_bin-linux-$host_arch.tar.xz" \
			--output-document="$output/qemu_bin-linux-$host_arch.tar.xz" \
			--output-file=/tmp/wget_qemu.log
		tar -xvf "qemu_bin-linux-$host_arch.tar.xz" -C ./ >/dev/null
		cd "$workspace"
		set +xe
		echo "INFO: Download qemu_bin-linux-$host_arch.tar.xz done"
	fi
}

test_qemu_bin() {
	set -xe
	cd "$output"
	./qemu_bins/lib/$ld_loader --library-path ./qemu_bins/lib ./qemu_bins/bin/qemu-system-x86_64 --version >/dev/null
	./qemu_bins/lib/$ld_loader --library-path ./qemu_bins/lib ./qemu_bins/bin/qemu-system-aarch64 --version >/dev/null
	./qemu_bins/static_qemu/bin/qemu-x86_64 --version >/dev/null
	./qemu_bins/static_qemu/bin/qemu-aarch64 --version >/dev/null
	set -xe
	cd "$workspace"
}

check_envs
download_qemu
test_qemu_bin
