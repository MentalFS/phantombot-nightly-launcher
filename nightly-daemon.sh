#!/bin/bash
set -e
{ for COMMAND in mkfifo timeout; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"
exec 200>lock

function prepare() {
	# lock
	flock -n 200 || exit 2

	# logs & rotate
	mkdir -p logs/service
	for ((LOG_B=15,LOG_A=14;LOG_B>0;LOG_A--,LOG_B--)); do
		test -f logs/service/service.$LOG_A.log \
		&& mv logs/service/service.$LOG_A.log logs/service/service.$LOG_B.log
	done
	test -f logs/service.log && mv logs/service.log logs/service/service.0.log
	exec &>logs/service.log
	exec 2>&1
}

function startup() {
	# fifo
	rm -f fifo
	mkfifo fifo
	trap cleanup_fifo EXIT ERR

	# launch
	. launch.sh < <(tail -f "$PWD/fifo")
}

function command() {
	if flock -n 200 || [ \! -p fifo ] ; then
		echo  "Bot not running." >&2
		exit 1
	fi

	if (($WHEN_IDLE)) && find logs/pointSystem/ -type f -mmin -60 | egrep -q . ; then
		echo  "Channel is still active." >&2
		exit 1
	fi

	echo "$COMMAND" > fifo
	timeout 30s tail -f logs/service.log
}

function update() {
	./nightly-update.sh --build "$BUILD" || exit 1
	{ exec "$(readlink -f "$0")" --no-update "$@"; exit 1; }
}

function cleanup_fifo() {
	fuser -TERM -k "$PWD/fifo" && echo FIFO TERMINATED
	pkill -f "^tail -f $PWD/fifo\$" && echo FIFO KILLED
}

function read_parameters() {
	BUILD="last monday"
	NO_UPDATE=0
	WHEN_IDLE=0

	while [[ "$1" == -* ]] ; do
		case "$1" in
			"--no-update")
				NO_UPDATE=1
				;;
			"--build")
				BUILD="$2"
				shift
				;;
			"--when-idle")
				WHEN_IDLE=1
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
test -z "$COMMAND" && prepare && { (($NO_UPDATE)) || update "$@"; startup "$@"; }
