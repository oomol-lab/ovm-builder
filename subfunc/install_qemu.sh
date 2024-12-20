#! /usr/bin/env bash
sudo apt -y install xz-utils tar binutils

output=${output:-/tmp/}
workspace=${workspace:-/tmp}
qemu_bin_tar="qemu_bin-linux-arm64.tar.xz"
sha1sum="2fd9e535a4a69cbfc78d03c74e2fcb036104bc08"

QEMU_URL="${QEMU_URL:-https://github.com/oomol/builded/releases/download/v1.6/qemu_bin-linux-arm64.tar.xz}"

if [[ $(uname -s) == Linux ]] && [[ $(uname -p) == aarch64 ]]; then
	echo "INFO: Install qemu_bin-linux-arm64"
	mkdir -p "$output" || {
		echo 'Error: create output dir for download qemu_bin_tar failed'
		exit 100
	}

	wget "$QEMU_URL" --output-document="$output/$qemu_bin_tar" --output-file=/tmp/wget_qemu.log && {
		echo "$sha1sum $qemu_bin_tar" >"$output/$qemu_bin_tar.sha1sum"
	} || {
		echo "Download Qemu failed"
		exit 100
	}

	cd "$output" && {
		mkdir ./qemu_bin
		tar -xvf $qemu_bin_tar -C ./
	} || {
		echo "Extract $qemu_bin_tar failed"
		exit 100
	} && cd "$workspace"

	cd "$output/qemu_bins/bin" && {
		strip --strip-unneeded *
	} && cd "$workspace"

	cd "$output" && {
		rm $qemu_bin_tar
		rm $qemu_bin_tar.sha1sum
	} && cd "$workspace"
fi

# Qemu will be installed in $output/qemu_bins
