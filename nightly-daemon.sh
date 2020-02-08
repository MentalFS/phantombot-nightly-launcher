#!/bin/bash
BUILD="last monday" # for really daily updates: --build today

set -e
{ for COMMAND in timeout; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"
exec 200>lock

# find logs/pointSystem/ -type f -mmin -60 | egrep -q . || echo EXIT

function startup() {
	echo START
}

function command() {
	if flock -n 200 || [ \! -p fifo ] ; then
		echo  "Bot not running." >&2
		exit 1
	fi

	echo "$COMMAND" > fifo
}

function update() {
	./nightly-update.sh --build "$BUILD" || exit 1
	{ exec "$(readlink -f "$0")" --no-update "$@"; exit 1; }
}

function read_parameters() {
	NO_UPDATE=0

	while [[ "$1" == -* ]] ; do
		case "$1" in
			"--no-update")
				NO_UPDATE=1
				;;
			"--build")
				BUILD="$2"
				shift
				;;
			"--")
				shift
				break
				;;
			*)
				echo "${0##*/}: unknown option $1" >&2
				exit 1
				;;
		esac
		shift
	done
	COMMAND="$@"
}

read_parameters "$@"
test -n "$COMMAND" && { command "$@"; exit; }
test -z "$COMMAND" && { (($NO_UPDATE)) || update "$@"; startup "$@"; }
