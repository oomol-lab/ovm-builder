#! /usr/bin/env bash
echo "=== Build PROOT ==="
echo "workspace: ${workspace:?}"
echo "output: ${output:?}"

if [[ "$SKIP_APT_GET_INSTALL" == "true" ]]; then
	echo "env SKIP_APT_GET_INSTALL set true, skip apt install package required"
else
	sudo -E apt update
	sudo -E apt install -y libarchive-dev libtalloc-dev uthash-dev build-essential git
fi

proot_src="$output/build_proot"
set -xe
rm -rf "$proot_src"
git clone https://github.com/proot-me/proot "$proot_src" --depth 1

cd "$proot_src"

CFLAG="-Wno-error=implicit-function-declaration" make -C src loader.elf -j8
CFLAG="-Wno-error=implicit-function-declaration" make -C src proot care -j8

rm -rf /usr/bin/proot
rm -rf /usr/local/bin/proot

cp src/proot /usr/bin/

proot --version
set +xe

echo "INFO: build proot done"
