#!/bin/bash
BUILD="last monday" # for really daily updates: --build today

set -e
{ for COMMAND in timeout; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

# find logs/pointSystem/ -type f -mmin -60 | egrep -q . || echo EXIT

function update() {
	echo "Updating... $@"
	./nightly-update.sh --build "$BUILD" || exit 1
	{ exec "$(readlink -f "$0")" --no-update "$@"; exit 1; }
}

function read_parameters() {
	NO_UPDATE=0
	while [[ "$1" == -* ]] ; do
		case "$1" in
			"--no-update")
				NO_UPDATE=1
				shift
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
}

# Only startup - Command injection where? Script or just leave FIFO?
read_parameters "$@"
{ (($NO_UPDATE)) || update "$@"; main "$@"; }
