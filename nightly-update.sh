#!/bin/bash
set -e

VERSION="master@%7Blast%20monday%7D"
PHANTOMBOT_URL="https://github.com/PhantomBot/nightly-build/raw/$VERSION/PhantomBot-nightly-lin.zip"
PHANTOMBOT_DE_URL="https://github.com/PhantomBotDE/PhantomBotDE/archive/$VERSION.zip"
PHANTOMBOT_CUSTOM_URL="https://github.com/TheCynicalTeam/Phantombot-Custom-Scripts/archive/$VERSION.zip"
PHANTOMBOT_CUSTOM_MODULES="challenge "

{ for COMMAND in git wget unzip; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function phantombot_update() {
	echo && echo "Updating Phantombot... $@"
	rm -rf nightly-build
	mkdir -pv nightly-download nightly-backup nightly-build/data/scripts/lang

	test -d "logs" && cp -prv "logs" nightly-build/data/
	test -1d "scripts/lang/custom" && cp -prv "scripts/lang/custom" nightly-build/data/scripts/lang/
	test -d "dbbackup" && cp -prv "dbbackup" nightly-build/data/
	test -d "addons" && cp -prv "addons" nightly-build/data/
	test -d "config" && cp -prv "config" nightly-build/data/

	echo && echo Backup...
	BACKUP_NAME="`date +%Y%m%d-%H%M%S`"
	tar cvzf "nightly-backup/$BACKUP_NAME-bot.tar.gz" --exclude 'nightly-*' --exclude fifo --exclude lock --remove-files *
	tar czf "nightly-backup/$BACKUP_NAME-bin.tar.gz" nightly-*.sh .git/
	find nightly-backup/ -type f -mtime +14 -print0 | xargs -0r rm -f

	echo && echo Download...
	wget -N "$PHANTOMBOT_URL" -O nightly-download/PhantomBot.zip.temp \
		|| test "$1" == "--ignore-error" || exit 1 \
		&& mv -fv nightly-download/PhantomBot.zip.temp nightly-download/PhantomBot.zip
	wget -N "$PHANTOMBOT_DE_URL" -O nightly-download/PhantomBotDE.zip.temp \
		|| test "$1" == "--ignore-error" || exit 1 \
		&& mv -fv nightly-download/PhantomBotDE.zip.temp nightly-download/PhantomBotDE.zip
	wget -N "$PHANTOMBOT_CUSTOM_URL" -O nightly-download/PhantomBot-Custom.zip.temp \
		|| test "$1" == "--ignore-error" || exit 1 \
		&& mv -fv nightly-download/PhantomBot-Custom.zip.temp nightly-download/PhantomBot-Custom.zip

	echo && echo Unpack...
	unzip nightly-download/PhantomBot.zip -d nightly-build/PhantomBot
	unzip nightly-download/PhantomBotDE.zip -d nightly-build/PhantomBotDE
	unzip nightly-download/PhantomBot-Custom.zip -d nightly-build/PhantomBot-Custom

	cp -prv nightly-build/PhantomBot/*/* .
	cp -prv nightly-build/PhantomBotDE/*/javascript-source/lang/german scripts/lang/
	ln -s german scripts/lang/deutsch
	mv -v nightly-build/PhantomBot-Custom/*/custom scripts/custom/cynicalteam
	mkdir -p scripts/lang/english/custom scripts/lang/german/custom
	mv -v nightly-build/PhantomBot-Custom/*/lang/english/custom scripts/lang/english/custom/cynicalteam
	mv -v nightly-build/PhantomBot-Custom/*/lang/german/custom scripts/lang/german/custom/cynicalteam
	cp -prv nightly-build/data/* .

	rm -rf nightly-build
}

function self_update() {
	echo "Self-Updating... $@"
	git --no-pager pull || test "$1" == "--ignore-error" || exit 1
	{ exec "$(readlink -f "$0")" --no-pull "$@"; exit 1; }
}

{ test "$1" == "--no-pull" || self_update "$@" && shift; phantombot_update "$@"; }
