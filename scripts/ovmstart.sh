#! /usr/bin/bash

set -o pipefail
MOUNT_FLAG=0

usage() {
	echo "Usage: $0 -p <podman-http-port> -s <data-disk-size> [--help]"
	echo "  -p, --podman-http-port <podman-http-port>: TCP port number of podman api service"
	echo "  -s, --data-disk-size <data-disk-size>:     Size of Data disk"
	echo "  --help: Display this help message"
	exit 100
}

parse_args() {
	opts=$(getopt -o p:s:h --long podman-http-port:,data-disk-size:,help -- "$@")

	if [ $? -ne 0 ]; then
		usage
	fi

	eval set -- "$opts"

	while true; do
		case "$1" in
		-p | --podman-http-port)
			podman_port_port="$2"
			shift 2
			;;
		-s | --data-disk-size)
			data_size="$2"
			shift 2
			;;
		-h | --help)
			usage
			;;
		--)
			shift
			break
			;;
		*)
			echo "Internal error!"
			usage
			;;
		esac
	done

	if [[ -z "${podman_port_port}" ]]; then
		echo "Need -p/--podman-http-port"
		exit 100
	fi

	if [[ -z "${data_size}" ]]; then
		echo "Need -s/--data-disk-size"
		exit 100
	fi

	echo "INFO: PODMAN API LISTEN PORT: ${podman_port_port}, DATA SIZE: ${data_size}"

}

mount_disk() {


	local containers_dir="/var/lib/containers/"

	mount | grep '/var/lib/containers/' && return

	test -d ${containers_dir} || echo "Directory /var/lib/containers/ not find!" && exit 100
	blocks_with_size=$(ls /sys/block/*/size)
	for blk in ${blocks_with_size}; do
		size="$(cat ${blk})"
		blkname=$(dirname ${blk})

		if [[ "${data_size}" = "${size}" ]]; then
			echo $blkname:$size
			blkname=$(basename ${blkname})
			echo mount /dev/${blkname} /var/lib/containers/
			mount /dev/${blkname} /var/lib/containers/
			ret=$?
			test ${ret} -eq 0 || echo "Failed: mount /dev/${blkname} /var/lib/containers/ " && exit 100
			MOUNT_FLAG=1
			break
		fi
	done
}

run_podman() {
	local podman_bin="/usr/bin/podman"

	if [[ -f /usr/bin/nc ]];then
		nc -w1 -vz "127.0.0.1:${podman_port_port}"
		test $? -eq 0 || echo "port ${podman_port_port} in used " && exit 100
	fi

	test -f ${podman_bin} || echo "${podman_bin} not find!" && exit 100
	echo ${podman_bin} system service --time=0 tcp://localhost:${podman_port_port}
	${podman_bin} system service --time=0 tcp://localhost:${podman_port_port}
	test ${ret} -eq 0 || echo "Failed: ${podman_bin} system service --time=0 tcp://localhost:${podman_port_port} " && exit 100
	PODMAN_RUNED=1
}


kill_old_podman(){
	if [[ ${PODMAN_RUNED} -eq 1 ]];then
		PID=$(ps aux| grep podman| grep -v grep | grep -v ${podman_port_port}| xargs | cut -d ' ' -f1 )
		kill -9 ${PID}
	fi
}

main() {
	parse_args "$@"
	mount_disk 
	run_podman
	kill_old_podman

}

main "$@"
