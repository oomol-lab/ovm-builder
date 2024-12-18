# `make` commands
  - `macos_arm64` : make ovm bootable image for macos arm64
  - `wsl2_amd64`  : make ovm wsl2 rootfs distribute



# Development environment
- `SKIP_BUILD_PROOT=true`: Skip build [proot](https://github.com/proot-me/proot)
- `SKIP_APT_GET_INSTALL=true`: Skip `apt update && apt install -y required package`
- `VM_PROVIDER=qemu`: using qemu as vm provider


## Dockerfile
```bash
docker build -t ubuntu-noble-build .
# Only if you need proxy
docker build --build-arg http_proxy=http://192.168.1.250:2020 --build-arg https_proxy=http://192.168.1.250:2020 -t ubuntu-noble-build .
```
