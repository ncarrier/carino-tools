#!/bin/sh

#set -x

export LANG=C

conn=${1:-carino}

while [ 1 ]; do
	sleep 1
	state=$(nmcli connection show ${conn} | grep GENERAL.STATE | sed 's/GENERAL.STATE: *//g')
	if [ "${state}" = "activated" ]; then
		continue
	fi
	echo not connected, try to connect
	nmcli connection up ${conn}
done
