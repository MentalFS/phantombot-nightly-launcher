#!/bin/bash
set -e
{ for COMMAND in git wget; do which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function phantombot_update() {
	echo "Updating Phantombot... $@"
}

function self_update() {
	echo "Self-Updating... $@"
	{ exec "$(readlink -f "$0")" --no-pull "$@"; exit 1; }
}

{ test "$1" == "--no-pull" || self_update "$@" && shift; phantombot_update "$@"; }
