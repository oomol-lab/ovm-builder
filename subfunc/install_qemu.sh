#! /usr/bin/env bash
arm64_sha1sum="94dad848d92085d499f18ea5cb88e5df82bbfcbe"
x86_64_sha1sum="0d51a587a6cc151999dc92dcea6df9d3c8042ae5"

host_arch=$(uname -p)
if [[ $host_arch == aarch64 ]]; then
	host_arch=arm64
	sha1sum_value=$arm64_sha1sum
fi

if [[ $host_arch == amd64 ]]; then
	host_arch=x86_64
	sha1sum_value=$x86_64_sha1sum
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
	sudo apt -y install xz-utils tar binutils
	if [[ $(uname -s) == Linux ]]; then
		echo "INFO: Download qemu_bin-linux-$host_arch.tar.xz"
		mkdir -p "$output" || {
			echo 'Error: create output dir for download qemu_bin_tar failed'
			exit 100
		}

		wget "https://github.com/oomol/builded/releases/download/v1.6/qemu_bin-linux-$host_arch.tar.xz" --output-document="$output/qemu_bin-linux-$host_arch.tar.xz" --output-file=/tmp/wget_qemu.log && {
			echo "$sha1sum_value qemu_bin-linux-$host_arch.tar.xz" >"$output/qemu_bin-linux-$host_arch.tar.xz.sha1sum"
		} || {
			echo "Download Qemu failed"
			exit 100
		}

		cd "$output" && {
			sha1sum -c qemu_bin-linux-$host_arch.tar.xz.sha1sum || {
				echo "qemu_bin-linux-$host_arch.tar.xz.sha1sum check failed"
				exit 100
			}

			tar -xvf "qemu_bin-linux-$host_arch.tar.xz" -C ./
		} || {
			echo "Extract qemu_bin-linux-arm64.tar.xz failed"
			exit 100
		} && cd "$workspace"
	fi
}

check_envs
download_qemu
