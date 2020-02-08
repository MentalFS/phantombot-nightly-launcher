#!/bin/bash
set -e
{ for COMMAND in git wget unzip tar; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function update() {
	PHANTOMBOT_URL="https://github.com/PhantomBot/nightly-build/raw/master@{$BUILD}/PhantomBot-nightly-lin.zip"
	PHANTOMBOT_DE_URL="https://github.com/PhantomBotDE/PhantomBotDE/archive/master@{$BUILD}.zip"
	PHANTOMBOT_CUSTOM_URL="https://github.com/TheCynicalTeam/Phantombot-Custom-Scripts/archive/master@{$BUILD}.zip"

	rm -rf nightly-temp
	mkdir -p nightly-download nightly-backup nightly-temp

	echo === Backup ===
	BACKUP_NAME="`date +%Y%m%d-%H%M%S`"
	mkdir -p logs scripts/lang/custom dbbackup addons config
	tar cvzf "nightly-backup/$BACKUP_NAME-conf.tar.gz" --remove-files logs scripts/lang/custom dbbackup addons config
	tar czf "nightly-backup/$BACKUP_NAME-bot.tar.gz" --exclude 'nightly-*' --exclude fifo --exclude lock --remove-files *
	tar czf "nightly-backup/$BACKUP_NAME-bin.tar.gz" nightly-*.sh .git/
	find nightly-backup/ -type f -mtime +7 -print0 | xargs -0r rm -f
	if ((UNINSTALL)) ; then
		rm -rf nightly-download nightly-temp fifo lock
		echo Uninstalled Phantombot.
		exit
	fi
	echo

	echo === PhantomBot update ===
	wget "$PHANTOMBOT_URL" -O nightly-download/PhantomBot.zip.temp \
		&& mv -fv nightly-download/PhantomBot.zip.temp nightly-download/PhantomBot.zip
	unzip -q nightly-download/PhantomBot.zip -d nightly-temp/PhantomBot
	find nightly-temp/PhantomBot/*/config -type f -name '*.aac' -o -name '*.ogg' -print0 | xargs -0r rm -f
	cp -pr nightly-temp/PhantomBot/*/* .
	echo

	if ((TRANSLATION)) ; then
		echo === Translation ===
		wget "$PHANTOMBOT_DE_URL" -O nightly-download/PhantomBotDE.zip.temp \
			&& mv -fv nightly-download/PhantomBotDE.zip.temp nightly-download/PhantomBotDE.zip
		unzip -q nightly-download/PhantomBotDE.zip -d nightly-temp/PhantomBotDE

		cp -pr nightly-temp/PhantomBotDE/*/javascript-source/lang/german scripts/lang/
		ln -s german scripts/lang/deutsch
		echo
	fi

	if ((CYNICAL_CUSTOM)) ; then
		echo === Custom modules by Cynical ===
		wget "$PHANTOMBOT_CUSTOM_URL" -O nightly-download/PhantomBot-Custom.zip.temp \
			&& mv -fv nightly-download/PhantomBot-Custom.zip.temp nightly-download/PhantomBot-Custom.zip
		unzip -q nightly-download/PhantomBot-Custom.zip -d nightly-temp/PhantomBot-Custom
		mv nightly-temp/PhantomBot-Custom/*/custom scripts/custom/cynicalteam
		mkdir -p scripts/lang/english/custom scripts/lang/german/custom
		mv nightly-temp/PhantomBot-Custom/*/lang/english/custom scripts/lang/english/custom/cynicalteam
		mv nightly-temp/PhantomBot-Custom/*/lang/german/custom scripts/lang/german/custom/cynicalteam
		echo
	fi

	echo === Finish ===
	tar xvzf "nightly-backup/$BACKUP_NAME-conf.tar.gz"
	rm -rf nightly-temp
}

function pull() {
	echo === Self-update ===
	git --no-pager pull || exit 1
	echo
	{ exec "$(readlink -f "$0")" --no-pull "$@"; exit 1; }
}

function read_parameters() {
	BUILD=today
	NO_PULL=0
	UNINSTALL=0
	TRANSLATION=1
	CYNICAL_CUSTOM=0

	while [[ "$1" == -* ]] ; do
		case "$1" in
			"--build")
				BUILD="$2"
				shift
				;;
			"--uninstall")
				UNINSTALL=1
				echo "Uninstalling PhantomBot!"
				break
				;;
			"--no-pull")
				NO_PULL=1
				;;
			"--no-translation")
				TRANSLATION=0
				;;
			"--cynical")
				CYNICAL_CUSTOM=1
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
{ (($NO_PULL)) || pull "$@"; update "$@"; }
