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

	test -n "$host_arch" || {
		echo 'Env: host_arch failed'
		exit 100
	}

	if [[ -z $target_arch ]]; then
		echo "Env target_arch empty"
		exit 100
	fi

	if [[ -z $raw_disk ]]; then
		echo "Env raw_disk empty"
		exit 100
	fi
}

boot_raw_arm64() {
	check_envs
	echo "INFO:Boot arm64 alpine disk"
	set -x
	"$output/qemu_bins/lib/$ld_loader" \
		--library-path "$output/qemu_bins/lib" \
		"$output/qemu_bins/bin/qemu-system-aarch64" -machine virt -cpu cortex-a72 -m 2048 \
		-nographic \
		-drive file="$raw_disk,format=raw,if=virtio" \
		-bios "$output/qemu_bins/share/qemu/edk2-aarch64-code.fd" \
		-netdev user,id=net0,restrict=n,hostfwd=tcp:127.0.0.1:10025-:22 \
		-device e1000,netdev=net0 -device virtio-balloon-pci,id=balloon0
	set +x
}

# Args1: bootable.img path
boot_raw_x86_64() {
	check_envs
	echo "INFO:Boot $raw_disk"
	set -x
	"$output/qemu_bins/lib/$ld_loader" \
		--library-path "$output/qemu_bins/lib" \
		"$output/qemu_bins/bin/qemu-system-x86_64" \
		-nographic -cpu max -smp 4 -m 2G \
		-netdev user,id=net0,restrict=n,hostfwd=tcp:127.0.0.1:10025-:22 \
		-device e1000,netdev=net0 \
		-device virtio-balloon-pci,id=balloon0 \
		-drive file="$raw_disk,format=raw,if=virtio"
	set -x
}

boot_raw_disk() {
	check_envs
	if [[ "$target_arch" == arm64 ]] || [[ "$target_arch" == aarch64 ]]; then
		set -x
		boot_raw_arm64 "$raw_disk"
		set +x
	elif [[ "$target_arch" == x86_64 ]] || [[ "$target_arch" == amd64 ]]; then
		set -x
		boot_raw_x86_64 "$raw_disk"
		set +x
	fi
}

main() {
	raw_disk="$1"
	target_arch="$2"

	check_envs
	boot_raw_disk

}

main "$@"
