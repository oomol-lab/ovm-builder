#! /usr/bin/env bash


echo "=== Build PROOT ==="
echo workspace: $workspace
echo  output: $output

set -ex
bash +x "$workspace/subfunc/install_package.sh"
sudo -E rm -rf $output/build_proot
git clone https://github.com/proot-me/proot $output/build_proot

cd $output/build_proot

CFLAG="-Wno-error=implicit-function-declaration" make -C src loader.elf -j8
CFLAG="-Wno-error=implicit-function-declaration" make -C src proot care -j8

rm -rf /usr/bin/proot
rm -rf /usr/local/bin/proot

cp src/proot /usr/bin/

proot --version
set +xe

echo "INFO: build proot done"
