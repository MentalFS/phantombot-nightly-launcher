#!/bin/bash
NIGHTLY_URL="https://github.com/PhantomBot/nightly-build/raw/master@%7Blast%20monday%7D/PhantomBot-nightly-lin.zip"

set -e
{ for COMMAND in git wget; do which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function phantombot_update() {
	echo "Updating Phantombot... $@"
	mkdir -p nightly-download nightly-build nightly-backup
	wget -N "$NIGHTLY_URL" -O nightly-download/PhantomBot-nightly-lin.zip.temp
	mv nightly-download/PhantomBot-nightly-lin.zip.temp nightly-download/PhantomBot-nightly-lin.zip
}

function self_update() {
	echo "Self-Updating... $@"
	{ exec "$(readlink -f "$0")" --no-pull "$@"; exit 1; }
}

{ test "$1" == "--no-pull" || self_update "$@" && shift; phantombot_update "$@"; }
