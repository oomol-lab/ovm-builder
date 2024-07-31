# Profile of amd64_wsl

# Do not change this plz
rootfs_type=alpine_based

# one package one line
preinstalled_packages="
	bash
	openrc
	podman
	busybox-mdev-openrc
	dmesg
	mount
	"
# rootfs_name:download_url
rootfs_url="
	alpine-minirootfs-3.20.2-x86_64.tar.gz:https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.2-x86_64.tar.gz
"
# name:download_url
other_url=""

# file_name:sha1sum
sha1sum="
	alpine-minirootfs-3.20.2-x86_64.tar.gz:9bbb7008afafb1579ed8f10ee3bdbddccc4275e9
"

# this profile only !
intended_func() {
	echo "($basename $0): write /etc/init.d/podman"
	if [[ -n ${rootfs_path} ]]; then
		set -x
		touch "${rootfs_path}/etc/init.d/podman"
		touch "${rootfs_path}/etc/conf.d/podman"
		set +x
		echo -n "${podman_init_rc}"       > "${rootfs_path}/etc/init.d/podman"
		echo -n "${podman_init_rc_confd}" > "${rootfs_path}/etc/conf.d/podman"
	fi
	# Create stop_all runlevel
	mkdir -p "${rootfs_path}/etc/runlevels/stop_all"
}

podman_init_rc='#!/sbin/openrc-run
supervisor=supervise-daemon

name="Podman API service"
description="Listening service that answers API calls for Podman"

command=/usr/bin/podman
command_args="system service ${podman_opts:=--time 0} $podman_uri"
command_user="${podman_user:=root}"

extra_commands="start_containers"
description_start_containers="Start containers with restart policy set to always"


start_containers() {
        ebegin "Starting containers with restart policy set to always"
        su "$podman_user" -s /bin/sh -c "$command start --all --filter restart-policy=always"
        eend $?
}

start_pre() {
        if [ "$podman_user" = "root" ]; then
                einfo "Configured as rootful service"
                checkpath -d -m 0755 /run/podman
        else
                einfo "Configured as rootless service"
                modprobe tun
                modprobe fuse
        fi
}

start_post() {
        start_containers
}
'

podman_init_rc_confd='# Configuration for /etc/init.d/podman

# See podman-system-service(1) for service description
# and available options.
podman_opts="--time 0"

# API endpoint in URI form. Leave empty to use defaults.
podman_uri="tcp://127.0.0.1:8888"

# Setting root user will start rootful service.
# Use any other user for rootless mode.
podman_user="root"
'
