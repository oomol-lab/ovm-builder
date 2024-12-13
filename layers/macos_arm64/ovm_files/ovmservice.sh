format_and_mount_var() {
	if [[ ! -b /dev/vdb ]]; then
		echo "/dev/vdb not find"
		exit 100
	fi

	mount_param="data=ordered"
	disk_uuid=8c29bbdf-db2c-4ef6-ad7f-76bd39481d0f

	blkid -U $disk_uuid
	ret=$?
	if [[ $ret -ne 0 ]]; then
		# initialize external disk
		mkfs.ext4 -U $disk_uuid -F /dev/vdb || {
			echo "Format /dev/vdb with $disk_uuid failed"
			exit 100
		}
		mkdir -p /dev/shm/var_temp
		mount -o "$mount_param" /dev/vdb /dev/shm/var_temp || {
			echo "Mount /dev/vdb into /dev/shm/var_temp failed"
			exit 100
		}
		cp -rf /var/* /dev/shm/var_temp || {
			echo 'Copy /var/ into /dev/shm/var_temp/ failed'
			exit 100
		}
		sync
		umount /dev/shm/var_temp || {
			echo "umount /dev/shm/var_temp failed"
			exit 100
		}
		mount -o "$mount_param" /dev/vdb /var/ || {
			echo "Mount $disk_uuid into /var failed"
			exit 100
		}
	else
		mount -o "$mount_param" /dev/vdb /var/ || {
			echo "Mount $disk_uuid into /var failed"
			exit 100
		}
	fi
}

mount_initfs() {
	ign_sh="/tmp/initfs/ovm_ign.sh"
	initfs_uuid=c5c8073159f40aa69d83a1e6c7aafb16b1e5
	initfs_mount_point="/tmp/initfs"
	mount -m -t virtiofs "${initfs_uuid}" "$initfs_mount_point" && {
		echo " Error: Mount virtiofs /tmp/initfs failed"
		exit 100

	}
	bash +x "${ign_sh}" && {
		echo "Error: Ignition scripts exec failed"
		exit 100
	}
}

umount_efi() {
	# if we do not unmount /boot/efi, when the vm got killed, the fsck will
	# take 1 second to fix the /boot/efi filesystem.
	# This is a complete waste of time and unnecessary
	umount /boot/efi/
}

umount_efi
format_and_mount_var
mount_initfs
sync