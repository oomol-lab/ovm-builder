FROM ubuntu:noble

ARG http_proxy
ARG https_proxy
ARG no_proxy

WORKDIR /root/MkRoot

COPY ./ /root/MkRoot/
RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/*

CMD ["./make", "macos_arm64"]

