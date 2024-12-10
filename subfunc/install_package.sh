if [[ $SKIP_APT_GET_INSTALL == "true" ]]; then
	echo "Warring: Skip apt install package required"
else
	set -ex
	sudo -E apt update
	sudo -E apt install -y libarchive-dev libtalloc-dev uthash-dev build-essential git qemu-user-static
	set -xe
fi
