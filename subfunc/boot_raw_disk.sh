#! /usr/bin/env bash
output=${output:-/tmp/}
workspace=${workspace:-/tmp}

check_qemu() {
	cd "$output" && {
		./qemu_bins/lib/ld-linux-aarch64.so.1 --library-path ./qemu_bins/lib  ./qemu_bins/bin/qemu-system-x86_64 --version
	} || {
		echo "Error: Qemu not installed"
		exit 100
	}
}


boot_raw_arm64(){
	echo "INFO:Boot arm64 alpine disk"
	echo "Not support, Skip"
}

boot_raw_x86_64(){
	echo "INFO:Boot x86_64 alpine disk"
	echo ./qemu_bins/lib/ld-linux-aarch64.so.1 \
		--library-path ./qemu_bins/lib  \
		./qemu_bins/bin/qemu-system-x86_64  \
		-nographic -cpu max -smp 4  -m 2G  \
		-netdev "user,id=net0,restrict=n,hostfwd=tcp:127.0.0.1:10025-:22" \
		-device "e1000,netdev=net0" \
		-device virtio-balloon-pci,id=balloon0 \
		-drive file="$1",format=raw,if=virtio
}

# arg1: PATH of bootable.img
# arg2: arch of bootable.img
# Example  boot_raw_disk alpine.img arm64
boot_raw_disk(){
	raw_disk="$1"
	arch="$2"
	if [[ "$arch" == arm64 ]];then
		boot_raw_arm64 "$raw_disk"
	elif [[ "$arch" == x86_64 ]];then
		boot_raw_x86_64 "$raw_disk"
	fi
}

check_qemu
# For now we only support boot x86_64 image
boot_raw_disk "$1" "$2"
