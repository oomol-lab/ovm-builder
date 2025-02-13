#! /usr/bin/env bash
set -e
# keep this script test able means this script do not require any envs
# from caller
x86_64_loader_ld="ld-linux-x86-64.so.2"
arm64_loader_ld="ld-linux-aarch64.so.1"

host_arch="$(uname -m)"
if [[ $host_arch == aarch64 ]] || [[ $host_arch == arm64 ]]; then
	host_arch=arm64
	ld_loader="$arm64_loader_ld"
fi

if [[ $host_arch == amd64 ]] || [[ $host_arch == x86_64 ]]; then
	host_arch=x86_64
	ld_loader="$x86_64_loader_ld"
fi

check_envs() {
	test -n "${output:?}" || {
		echo 'env: output failed'
		exit 100
	}

	test -n "${workspace:?}" || {
		echo 'env: workspace failed'
		exit 100
	}

	test -n "${host_arch:?}" || {
		echo 'env: host_arch failed'
		exit 100
	}
	test -n "${ld_loader:?}" || {
		echo 'env: ld_loader failed'
		exit 100
	}
}

download_qemu() {

	echo "download qemu_bin-linux-$host_arch.tar.xz"
	sudo -E apt update
	sudo -E apt -y install xz-utils tar binutils zstd wget

	qemu_tar="$output/qemu_bin-linux-$host_arch.tar.xz"

	mkdir -p "$output"
	wget -c "https://github.com/oomol/builded/releases/download/v1.6/qemu_bin-linux-$host_arch.tar.xz" \
		--output-document="$qemu_tar" \
		--output-file="$(dirname "$qemu_tar")/qemu_wget.log"
	echo "download $qemu_tar finished"

	tar -xvf "$qemu_tar" -C "$output" >"$output/qemu_tar.log"
	echo "extract $qemu_tar finished"
}

test_qemu_bin() {
	ld_loader="$output/qemu_bins/lib/$ld_loader"
	libs_dir="$(dirname "$ld_loader")"
	"$ld_loader" --library-path "$libs_dir" "$output/qemu_bins/bin/qemu-system-x86_64" --version
	"$ld_loader" --library-path "$libs_dir" "$output/qemu_bins/bin/qemu-system-aarch64" --version
	"$output/qemu_bins/static_qemu/bin/qemu-x86_64" --version
	"$output/qemu_bins/static_qemu/bin/qemu-aarch64" --version
}

check_envs
download_qemu
test_qemu_bin
