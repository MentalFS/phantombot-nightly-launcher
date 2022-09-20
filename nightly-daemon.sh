#!/bin/bash
set -e
{ for COMMAND in flock mkfifo fuser pkill timeout; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"
exec 100>&1 200>nightly-daemon.lock

function prepare() {
	# lock
	flock -n 200 || { (($SILENT)) || echo Bot already running. >&2 ; exit 2; }

	# log & rotate
	mkdir -p logs/nightly-daemon
	(($NO_LOGROTATE)) || rotate_logs
	(($SILENT)) || exec &> >(tee -a nightly-daemon.log)
	(($SILENT)) && exec &>>nightly-daemon.log
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

	echo "$COMMAND" > nightly-daemon.fifo
	(($SILENT)) || { timeout 3s tail -f -n8 nightly-daemon.log | egrep --color '^|\[CONSOLE\]'; echo; }
}

function update() {
	./nightly-update.sh --build "$BUILD" || exit 1
	echo
	exec 1>&100 2>&1 100>&-
	{ exec "$(readlink -f "$0")" --no-update --no-logrotate "$@"; exit 1; }
}

function rotate_logs()  {
	for ((LOG_B=15,LOG_A=14;LOG_B>0;LOG_A--,LOG_B--)); do
		test -f nightly-daemon.$LOG_B.log && mv nightly-daemon.$LOG_B.log logs/nightly-daemon/
		test -f logs/nightly-daemon/nightly-daemon.$LOG_A.log \
		&& mv logs/nightly-daemon/nightly-daemon.$LOG_A.log logs/nightly-daemon/nightly-daemon.$LOG_B.log
	done
	test -f nightly-daemon.log && mv nightly-daemon.log logs/nightly-daemon/nightly-daemon.0.log
	touch nightly-daemon.log
}

function cleanup_fifo() {
	fuser -TERM -k "$PWD/nightly-daemon.fifo" && echo FIFO TERMINATED
	pkill -f "^tail -f $PWD/nightly-daemon.fifo\$" && echo FIFO KILLED
}

function read_parameters() {
	BUILD="3 days ago"
	NO_UPDATE=0
	NO_LOGROTATE=0
	SILENT=0

	while [[ "$1" == -* ]] ; do
		case "$1" in
			"--no-update")
				NO_UPDATE=1
				;;
			"--no-logrotate")
				NO_LOGROTATE=1
				;;
			"--build")
				BUILD="$2"
				shift
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
