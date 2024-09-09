#! /usr/bin/env bash

make_exit_disk() {
	if [[ -n $disk_size ]]; then
		# Do nothing
		echo -n ""
	else
		echo 'Error: env $disk_size empty'
		exit 100
	fi
	if [[ -n $disk_format ]]; then
		echo -n ""
	else
		echo 'Error: env $disk_format empty'
		exit 100
	fi
	if [[ -n $disk_uuid ]]; then
		echo -n ""
	else
		echo 'Error: env $disk_uuid empty'
		exit 100
	fi
	if [[ -n $disk_name ]]; then
		echo -n ""
	else
		echo 'Error: env $disk_name empty'
		exit 100
	fi
	disk_name="ovm_disk.raw"
	echo "Make a $output/$disk_name,size:$disk_size,format:$disk_format,uuid:$disk_uuid"
	set -x
	truncate -s 2048M "$output/$disk_name"
	sudo mkfs.ext4 -U 8a3219d0-4002-4cd9-8cb1-f3ffe52451f1 -F ovm_disk.raw
	set +x
}

copy_rootfs_into_disk(){
	ovm_disk_mount_point=/tmp/ovm_disk_mount_point
	set -x
	mkdir -p $ovm_disk_mount_point
	sudo -E mount $output/$disk_name $ovm_disk_mount_point
	sudo -E tar -xvf $rootfs_archive -C $ovm_disk_mount_point
	sync
	umount $ovm_disk_mount_point
	set +x
}

main() {
	if [[ -n $output ]]; then
		echo -n ""
	else
		echo 'Error: env $output empty'
		exit 100
	fi
	make_exit_disk
	copy_rootfs_into_disk
}

main
