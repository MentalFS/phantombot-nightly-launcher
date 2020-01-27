#!/bin/bash
set -e

# TODO/WISHLIST
# - Cache, reduce downloads (prebuild on GitHub?)

VERSION="master@%7Blast%20monday%7D"
PHANTOMBOT_URL="https://github.com/PhantomBot/nightly-build/raw/$VERSION/PhantomBot-nightly-lin.zip"
PHANTOMBOT_DE_URL="https://github.com/PhantomBotDE/PhantomBotDE/archive/$VERSION.zip"
PHANTOMBOT_CUSTOM_URL="https://github.com/TheCynicalTeam/Phantombot-Custom-Scripts/archive/$VERSION.zip"

{ for COMMAND in git wget unzip; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function phantombot_update() {
	echo "Updating Phantombot... $@"
	mkdir -pv nightly-download nightly-build nightly-backup

	test -d "logs" && cp -prv "logs" nightly-build/
	test -d "scripts/lang/custom" && cp -prv "scripts/lang/custom" nightly-build/scripts/lang/
	test -d "dbbackup" && cp -prv "dbbackup" nightly-build/
	test -d "addons" && cp -prv "addons" nightly-build/
	test -d "config" && cp -prv "config" nightly-build/

	echo Backup...
	BACKUP_NAME="`date +%Y%m%d_%H%M%S`"
	tar cvzf "nightly-backup/$BACKUP_NAME-bot.tar.gz" --exclude 'nightly-*' --exclude fifo --exclude lock * #TODO --remove-files
	tar cvzf "nightly-backup/$BACKUP_NAME-bin.tar.gz" nightly-*.sh .git/
	find nightly-backup/ -type f -mtime +90 -print0 | xargs -0r rm -f

	echo Download...
	wget -N "$PHANTOMBOT_URL" -O nightly-download/PhantomBot.zip.temp \
		|| test "$1" == "--ignore-error" || exit 1 \
		&& mv -fv nightly-download/PhantomBot.zip.temp nightly-download/PhantomBot.zip
	wget -N "$PHANTOMBOT_DE_URL" -O nightly-download/PhantomBotDE.zip.temp \
		|| test "$1" == "--ignore-error" || exit 1 \
		&& mv -fv nightly-download/PhantomBotDE.zip.temp nightly-download/PhantomBotDE.zip
	wget -N "$PHANTOMBOT_CUSTOM_URL" -O nightly-download/PhantomBot-Custom.zip.temp \
		|| test "$1" == "--ignore-error" || exit 1 \
		&& mv -fv nightly-download/PhantomBot-Custom.zip.temp nightly-download/PhantomBot-Custom.zip
}

function self_update() {
	echo "Self-Updating... $@"
	git --no-pager pull || test "$1" == "--ignore-error" || exit 1
	{ exec "$(readlink -f "$0")" --no-pull "$@"; exit 1; }
}

{ test "$1" == "--no-pull" || self_update "$@" && shift; phantombot_update "$@"; }
