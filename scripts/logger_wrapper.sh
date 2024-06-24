#! /bin/sh

# Wraps awk to redirect error and stdout to `tee-ovm`, 
# This script works with openrc's supervise-daemon as a logger
# - stdout to `/proc/${TEE_OVM_PID}/fd/1`
# - stderr to `/proc/${TEE_OVM_PID}/fd/2`

TEE_OVM_PID=$(busybox ps aux | grep -v grep | grep tee-ovm | xargs | busybox cut -d ' ' -f1)

test -z ${TEE_OVM_PID} && {
	echo "Error: ovm-tee not running !"
	exit 100
}

logger_stdout() {
 	busybox	awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >/proc/${TEE_OVM_PID}/fd/1
}

logger_stderr() {
	busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >/proc/${TEE_OVM_PID}/fd/2
}

stdtype=${1}
if [[ $stdtype = "stdout" ]]; then
	logger_stdout
else
	logger_stderr
fi
