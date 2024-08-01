FROM ubuntu:jammy

LABEL maintainer="zzheasy@gmail.com"

RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/' /etc/apt/sources.list
RUN apt-get update && \
	apt install libarchive-dev uthash-dev gcc make

WORKDIR /opt/MkRoot
COPY . .
RUN mkdir -p ./tools
RUN ./make amd64_wsl2
CMD bash
