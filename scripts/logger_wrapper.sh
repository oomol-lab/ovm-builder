#! /bin/sh

# Wraps awk to redirect error and stdout to `ovmd`
# This script works with openrc's supervise-daemon as a logger
# If ovmd running...
# - stdout to `/proc/${OVMD_PID}/fd/1`
# - stderr to `/proc/${OVMD_PID}/fd/2`
# If ovmd not running...
# - stdout to `/tmp/ovm_log_stdout.log`
# - stderr to `/tmp/ovm_log_stderr.log`

OVMD_PID=$(busybox ps aux | grep -v grep | grep ovmd | xargs | busybox cut -d ' ' -f1)

test -z ${OVMD_PID} && {
	echo "ovmd not running, all message log to /tmp/ovm_log_{stderr,stdout}.log"
	LOG_TYPE="file" 
} || {
	echo "ovmd running, all mesage redirect to ovmd"
	LOG_TYPE="process"
}

logger_stdout() {
	test ${LOG_TYPE} = "process" && {
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >/proc/${OVMD_PID}/fd/1
	} || {
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >>/tmp/ovm_log_stdout.log
	}
}

logger_stderr() {
	test ${LOG_TYPE} = "process" && {
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >/proc/${OVMD_PID}/fd/2
	} || {
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >>/tmp/ovm_log_stderr.log
	}
}

stdtype=${1}
if [[ $stdtype = "stdout" ]]; then
	logger_stdout
else
	logger_stderr
fi
