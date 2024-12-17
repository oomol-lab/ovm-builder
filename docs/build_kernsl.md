# Build kernel scripts

## Usage
```sh
$ ./build_kernel.sh \
    --kernel-version=<next|mainline|stable|longterm> \
    --kernel-config=tmp/config \
    --menuconfig  \
    --dts=rockchip/rk3399-eaidk-610.dts # or --dtb=/tmp/mydtb.dtb \
    --output=/tmp/kernel_out
```
