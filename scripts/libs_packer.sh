#! /bin/bash
set -e 
# libs_packer.sh
# Analyze dependencies and package dependencies and target ELF files

# HELP_BEGIN
# Usage:
# libs_packer.sh [OPTS] FILE
# OPTIONS
#       --version
#              Print the version number of libs_packer.sh.
#       --list ELF_OBJ
#              Prints the shared objects (shared libraries) required by each program or shared object
#
#       --pack ARCHIVE
#               Pack the shared objects (shared libraries) required by each program or shared object
# HELP_END
#

SHORTOPTS="lpvh"
LONGOPTS="list,pack,version,help"
LIST=true
PACK=false

PARSED=$(getopt --options=$SHORTOPTS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
	exit 1
else
	eval set -- "$PARSED"
fi

usage() {
	sed -n '/# HELP_BEGIN/,/# HELP_END/ {
    	/# HELP_BEGIN/d	
	/# HELP_END/{d;q}
	p
	}' $0
}

while true; do
	case "$1" in
	-v | --version)
		VERSION=true
		basename $0
		echo "  Version: 1.0 $(uname -m)"
		exit 0
		shift
		;;
	-h | --help)
		HELP=true
		usage
		exit 0
		shift
		;;
	-l | --list)
		LIST=true
		shift
		;;
	-p | --pack)
		PACK=true
		shift
		;;
	--)
		shift
		break
		;;
	*)
		echo "Unknown option: $1"
		exit 1
		;;
	esac
done

# Note:
# For now only support ELF linked with glibc.
# This scripts need to be more general in the future
ELF_LIST=()
ELF_LIST+="${*}"
for elf in $ELF_LIST; do
	echo "Analyze ${elf}..."
	LIBS=()
	LIBS+=$(ldd ${elf} | grep -v linux-vdso | cut -d '>' -f2 | cut -d '(' -f1)
	LIBS+=${elf}
	
	LIST=$(echo "${LIBS[@]}" | xargs)
	for wb in $LIST; do
		test ${PACK} = "true" && {
			OUTPUT_DIR=${OUTPUT_DIR:="/tmp/"}
			echo tar --dereference -rvf "${OUTPUT_DIR}/deps.tar" "${wb}"
			tar --dereference -rvf "${OUTPUT_DIR}/deps.tar" "${wb}" > /dev/null 2>&1 
		} || echo "  ${elf} require: ${wb}"
	done
done
