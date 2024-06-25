#! /bin/sh

# Wraps awk to redirect error and stdout to `tee-ovm`
# This script works with openrc's supervise-daemon as a logger
# If tee-ovm running...
# - stdout to `/proc/${TEE_OVM_PID}/fd/1`
# - stderr to `/proc/${TEE_OVM_PID}/fd/2`
# If tee-ovm not running...
# - stdout to `/tmp/ovm_log_stdout.log`
# - stderr to `/tmp/ovm_log_stderr.log`

TEE_OVM_PID=$(busybox ps aux | grep -v grep | grep tee-ovm | xargs | busybox cut -d ' ' -f1)

test -z ${TEE_OVM_PID} && {
	echo "ovm-tee not running, all message log to /tmp/ovm_log_{stderr,stdout}.log"
	LOG_TYPE="filebased" 
} || {
	echo "ovm-tee running, all mesage redirect to tee-ovm"
	LOG_TYPE="teebased"
}

logger_stdout() {
	test ${LOG_TYPE} = "teebased" && {
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >/proc/${TEE_OVM_PID}/fd/1
	} || {
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >>/tmp/ovm_log_stdout.log
	}
}

logger_stderr() {
	test ${LOG_TYPE} = "teebased" && {
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " " $0 }' >/proc/${TEE_OVM_PID}/fd/2
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
