#! /usr/bin/bash

usage() {
	echo "Usage: $0 -p <podman-http-port> -s <data-disk-size> [--help]"
	echo "  -p, --podman-http-port <podman-http-port>: TCP port number of podman api service"
	echo "  -s, --data-disk-size <data-disk-size>:     Size of Data disk"
	echo "  --help: Display this help message"
	exit 1
}


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

test -d /var/lib/containers/ || echo "Directory /var/lib/containers/ not find!" &&  exit 100

blocks_with_size=$(ls /sys/block/*/size)
for blk in ${blocks_with_size}; do

	size="$(cat ${blk})"
	blkname=$(dirname ${blk})

	if [[ ${data_size} = ${size} ]]; then
		echo $blkname:$size
		blkname=$(basename ${blkname})
		echo  mount /dev/${blkname} /var/lib/containers/
		mount /dev/${blkname} /var/lib/containers/
		echo  podman system service --time=0 tcp://localhost:${podman_port_port}
		podman system service --time=0 tcp://localhost:${podman_port_port}
		break
	fi
done

exit 0
