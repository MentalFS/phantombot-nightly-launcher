#!/bin/bash
set -e
{ for COMMAND in git wget unzip tar; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function main() {
	PHANTOMBOT_URL="https://github.com/PhantomBot/nightly-build/raw/master@{$BUILD}/PhantomBot-nightly-lin.zip"
	PHANTOMBOT_DE_URL="https://github.com/PhantomBotDE/PhantomBotDE/archive/master@{$BUILD}.zip"
#	PHANTOMBOT_CUSTOM_URL="https://github.com/TheCynicalTeam/Phantombot-Custom-Scripts/archive/master@{$BUILD}.zip"

	echo && echo "Updating Phantombot... $@"
	rm -rf nightly-temp
	mkdir -p nightly-download nightly-backup nightly-temp

	echo && echo Backup...
	BACKUP_NAME="`date +%Y%m%d-%H%M%S`"
	mkdir -p logs scripts/lang/custom dbbackup addons config
	tar cvzf "nightly-backup/$BACKUP_NAME-conf.tar.gz" --remove-files logs scripts/lang/custom dbbackup addons config
	tar czf "nightly-backup/$BACKUP_NAME-bot.tar.gz" --exclude 'nightly-*' --exclude fifo --exclude lock --remove-files *
	tar czf "nightly-backup/$BACKUP_NAME-bin.tar.gz" nightly-*.sh .git/
	find nightly-backup/ -type f -mtime +7 -print0 | xargs -0r rm -f
	((UNINSTALL)) && rm -rf nightly-download nightly-temp && exit

	echo && echo Download...
	wget -N "$PHANTOMBOT_URL" -O nightly-download/PhantomBot.zip.temp \
		&& mv -fv nightly-download/PhantomBot.zip.temp nightly-download/PhantomBot.zip
	wget -N "$PHANTOMBOT_DE_URL" -O nightly-download/PhantomBotDE.zip.temp \
		&& mv -fv nightly-download/PhantomBotDE.zip.temp nightly-download/PhantomBotDE.zip
#	wget -N "$PHANTOMBOT_CUSTOM_URL" -O nightly-download/PhantomBot-Custom.zip.temp \
#		&& mv -fv nightly-download/PhantomBot-Custom.zip.temp nightly-download/PhantomBot-Custom.zip

	echo && echo Unpack...
	unzip -q nightly-download/PhantomBot.zip -d nightly-temp/PhantomBot
	find nightly-temp/PhantomBot/*/config -type f -name '*.aac' -o -name '*.ogg' -print0 | xargs -0r rm -f
	unzip -q nightly-download/PhantomBotDE.zip -d nightly-temp/PhantomBotDE
#	unzip -q nightly-download/PhantomBot-Custom.zip -d nightly-temp/PhantomBot-Custom

	cp -pr nightly-temp/PhantomBot/*/* .
	cp -pr nightly-temp/PhantomBotDE/*/javascript-source/lang/german scripts/lang/
	ln -s german scripts/lang/deutsch
#	mv nightly-temp/PhantomBot-Custom/*/custom scripts/custom/cynicalteam
#	mkdir -p scripts/lang/english/custom scripts/lang/german/custom
#	mv nightly-temp/PhantomBot-Custom/*/lang/english/custom scripts/lang/english/custom/cynicalteam
#	mv nightly-temp/PhantomBot-Custom/*/lang/german/custom scripts/lang/german/custom/cynicalteam

	tar xvzf "nightly-backup/$BACKUP_NAME-conf.tar.gz"
	rm -rf nightly-temp
}

function pull() {
	echo "Self-Updating... $@"
	git --no-pager pull || exit 1
	{ exec "$(readlink -f "$0")" --no-pull "$@"; exit 1; }
}

function read_parameters() {
	BUILD=today
	NO_PULL=0
	UNINSTALL=0
	while [[ "$1" == -* ]] ; do
		case "$1" in
			"--build")
				BUILD="$2"
				shift
				;;
			"--uninstall")
				UNINSTALL=1
				;;
			"--no-pull")
				NO_PULL=1
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

read_parameters "$@"
{ (($NO_PULL)) || pull "$@"; main "$@"; }
