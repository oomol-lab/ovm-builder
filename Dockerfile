FROM ubuntu:jammy

LABEL maintainer="zzheasy@gmail.com"

RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/' /etc/apt/sources.list
RUN apt-get update && \
	apt install -y git tar coreutils gzip \
	libncurses-dev util-linux meson ninja-build bzip2 \
	rustc protobuf-compiler busybox e2fsprogs libcap-dev locales-all make \
	bzip2 pkg-config libseccomp-dev libgpgme-dev cargo libarchive-dev \
	libtalloc-dev uthash-dev libglib2.0-dev libseccomp-dev pkg-config \
	runc iptables curl openssl gcc-aarch64-linux-gnu xz-utils sudo wget \
	g++-aarch64-linux-gnu gcc-aarch64-linux-gnu

WORKDIR /opt/MkRoot
COPY . .
RUN mkdir -p ./tools
RUN ./make
CMD bash
