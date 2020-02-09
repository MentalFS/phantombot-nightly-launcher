#!/bin/bash
set -e
{ for COMMAND in mkfifo timeout; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"
exec 200>nightly-daemon.lock

function prepare() {
	# lock
	flock -n 200 || { (($SILENT)) || echo Bot already running. >&2 ; exit 2; }

	# log & rotate
	test -f nightly-daemon.2.log && mv -f nightly-daemon.2.log nightly-daemon.3.log
	test -f nightly-daemon.1.log && mv -f nightly-daemon.1.log nightly-daemon.2.log
	test -f nightly-daemon.log && mv -f nightly-daemon.log nightly-daemon.1.log
	(($SILENT)) || echo Output is redirected to $PWD/nightly-daemon.log
	exec &>nightly-daemon.log
	exec 2>&1
}

function startup() {
	# fifo
	rm -f nightly-daemon.fifo
	mkfifo nightly-daemon.fifo
	trap cleanup_fifo EXIT ERR

	# launch
	echo === Launch ===
	. launch.sh "$PWD" < <(tail -f "$PWD/nightly-daemon.fifo")
}

function command() {
	if flock -n 200 || [ \! -p nightly-daemon.fifo ] ; then
		(($SILENT)) || echo  "Bot not running." >&2
		exit 1
	fi

	if (($WHEN_IDLE)) && find logs/pointSystem/ -type f -mmin -60 | egrep -q . ; then
		(($SILENT)) || echo  "Channel is still active." >&2
		exit 1
	fi

	echo "$COMMAND" > nightly-daemon.fifo
	(($SILENT)) || { timeout 5s tail -f -n3 nightly-daemon.log; echo; }
}

function update() {
	./nightly-update.sh --build "$BUILD" || exit 1
	echo
	{ exec "$(readlink -f "$0")" --no-update "$@"; exit 1; }
}

function cleanup_fifo() {
	fuser -TERM -k "$PWD/nightly-daemon.fifo" && echo FIFO TERMINATED
	pkill -f "^tail -f $PWD/nightly-daemon.fifo\$" && echo FIFO KILLED
}

function read_parameters() {
	BUILD="last monday"
	NO_UPDATE=0
	WHEN_IDLE=0
	SILENT=0

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
			"--silent")
				SILENT=1
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
test -z "$COMMAND" && { prepare; (($NO_UPDATE)) || update "$@"; startup "$@"; }
