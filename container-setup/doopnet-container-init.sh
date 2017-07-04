#!/bin/bash

startProcess() {
	PROCESS=$*
	PROCESS_STR="${PROCESS:0:-1}[${PROCESS: -1}]"
	RET=$(ps ax | grep -c "$PROCESS_STR")
	[ "$RET" -lt 1 ] && $PROCESS && echo "$PROCESS started"
}

#######

MYNAME=$(basename $0)

MYNAME_STR="${MYNAME:0:-1}[${MYNAME: -1}]"
RET=$(ps ax | grep -c "$MYNAME_STR")
[ "$RET" -gt 2 ] && exit 1

startProcess /usr/sbin/sshd &

