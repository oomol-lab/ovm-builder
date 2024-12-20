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

check_qemu() {
	target_arch="$2"
	cd "$output" && {
		./qemu_bins/lib/$ld_loader --library-path ./qemu_bins/lib ./qemu_bins/bin/qemu-system-$target_arch --version
	} || {
		echo "Error: Qemu not installed or install with error"
		exit 100
	}
}

boot_raw_arm64() {
	echo "INFO:Boot arm64 alpine disk"
}

boot_raw_x86_64() {
	echo "INFO:Boot x86_64 alpine disk"
}

# arg1: PATH of bootable.img
# arg2: arch of bootable.img
# Example  boot_raw_disk alpine.img arm64
boot_raw_disk() {
	raw_disk_path="$1"
	bootable_image_arch="$2"
	if [[ "$bootable_image_arch" == arm64 ]]; then
		boot_raw_arm64 "$raw_disk"
	elif [[ "$bootable_image_arch" == x86_64 ]]; then
		boot_raw_x86_64 "$raw_disk"
	fi
}

check_envs
check_qemu "$@"
