#! /usr/bin/env bash

# Wraps awk to redirect error and stdout to `ovmd`
# This script works with openrc's supervise-daemon as a logger
# If ovmd running...
# - stdout to `/proc/${OVMD_PID}/fd/1`
# - stderr to `/proc/${OVMD_PID}/fd/2`
# If ovmd not running...
# - stdout to `/tmp/ovm_log_stdout.log`
# - stderr to `/tmp/ovm_log_stderr.log`

# make sure we not using busybox build-in tools
prerun() {
	msg=$(ps --help 2>&1 | grep BusyBox)
	ret=$?
	if [[ $ret -eq 0 ]]; then
		echo "Warring: ps is busybox built-in command"
		exit 100
	fi
}

find_ovmd_pid() {
	this_pid=$$
	rs=$(ps -eo pid:10,comm,args)
	rs=$(echo -n "$rs" | grep ovmd | grep -v grep)
	rs=$(echo -n "$rs" | grep -v ${this_pid} | awk '{print $1}')
	rs=$(echo -n "$rs" | xargs)
	OVMD_PID=${rs}
}

logger_stdout() {
	if [[ ${LOG_TYPE} = "ovmd" ]];then
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " > " $0 }' >/proc/${OVMD_PID}/fd/1
	elif [[ ${LOG_TYPE} = "file" ]];then
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " > " $0 }' >>/tmp/ovm_log_stdout.log
	fi
}

logger_stderr() {
	if [[ ${LOG_TYPE} = "ovmd" ]];then
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " > " $0 }' >/proc/${OVMD_PID}/fd/2
	elif [[ ${LOG_TYPE} = "file" ]];then
		busybox awk '{ print ENVIRON["RC_SVCNAME"] " > " $0 }' >>/tmp/ovm_log_stderr.log
	fi
}

main() {
	stdtype=${1}
	prerun
	find_ovmd_pid

	test -z ${OVMD_PID} && {
		echo "ovmd not running, all message log to /tmp/ovm_log_{stderr,stdout}.log"
		LOG_TYPE="file"
	} || {
		echo "ovmd running, all mesage redirect to ovmd,pid=${OVMD_PID}"
		LOG_TYPE="ovmd"
	}

	if [[ $stdtype = "stdout" ]];then
		logger_stdout
	elif [[ $stdtype = "stderr" ]];then
		logger_stderr
	fi
}

main "$@"
