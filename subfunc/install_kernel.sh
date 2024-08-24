#! /usr/bin/env bash
set -o pipefail
backup_kernel() {
	cd "${_cwd_}" || {
		echo "Error: Change dir to ${_cwd_} failed"
		exit 100
	}
	old_kv=$(uname -r)
	echo "Back old kernel ${old_kv}"
	msg=$(sudo tar -cvf "old_${old_kv}.tar" "/lib/modules/${old_kv}" "/boot/" 2>&1)
	ret=$?
	if [[ $ret -ne 0 ]]; then
		echo "Error: Back old kernel ${old_kv} failed"
		echo "${msg}"
		exit 100
	fi
}

install_modules() {
	cd "${_cwd_}" || {
		echo "Change dir to ${_cwd_} failed"
		exit 100
	}
	echo "Install modules...."
	if [[ -d ./lib/modules/${kv} ]]; then
		set -xe
		sudo cp -rf "./lib/modules/${kv}" /lib/modules/
		set +xe
	else
		echo "Error: not a directory ./lib/modules/${kv}"
		exit 100
	fi
}

install_kernel_image() {
	if [[ -z ${kv} ]]; then
		echo "Error: env kv is empty, stop"
		exit 100
	fi
	set -xe
	sudo cp -rf Image.gz "/boot/vmlinuz-${kv}"
	cd /boot
	sudo ln -sf "vmlinuz-${kv}" vmlinuz
	sudo ln -sf "vmlinuz-${kv}" Image
	cd "$_cwd_"
	set +xe
}

install_dtb() {
	if [[ -z ${kv} ]]; then
		echo "Error: env kv is empty, stop"
		exit 100
	fi
	set -xe
	dtb_path="/boot/dtb-${kv}/rockchip"
	sudo mkdir -p "${dtb_path}"
	sudo cp rk3399-eaidk-610.dtb "${dtb_path}"
	cd /boot
	sudo rm -rf dtb
	sudo ln -sf "dtb-${kv}" dtb
	set +xe
}

install_config() {
	if [[ -z ${kv} ]]; then
		echo "Error: env kv is empty, stop"
		exit 100
	fi
	set -xe
	cd "${_cwd_}"
	sudo cp .config "/boot/config-${kv}"
	set +xe
}
install_systembol() {
	if [[ -z ${kv} ]]; then
		echo "Error: env kv is empty, stop"
		exit 100
	fi
	set -xe
	cd "${_cwd_}"
	sudo cp System.map "/boot/System.map-${kv}"
	set +xe
}

install_initrd(){
	set -ex
	cd /boot
	sudo ln -sf "uInitrd-${kv}" uInitrd
	sudo ln -sf "initrd.img-${kv}" initrd.img
	set +ex
}

main() {
	_cwd_=$(pwd)
	kv=$(find ./lib/modules/ -maxdepth 1 -printf '%P\n' 2>&1 | xargs | head -n1)
	ret=$?
	if [[ $ret -ne 0 ]]; then
		echo "Error: ./lib/modules/ no kernel modules, stop"
		exit 100
	fi
	backup_kernel
	install_modules
	install_kernel_image
	install_dtb
	install_config
	install_systembol
	install_initrd
	sudo update-initramfs -c -k "${kv}"
}

sudo echo -n ""
main
