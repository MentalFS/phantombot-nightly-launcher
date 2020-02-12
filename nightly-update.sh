#!/bin/bash
set -e
{ for COMMAND in git wget unzip tar; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function update() {
	PHANTOMBOT_URL="https://github.com/PhantomBot/nightly-build/raw/master@{$BUILD}/PhantomBot-nightly-lin.zip"
	PHANTOMBOT_DE_URL="https://github.com/PhantomBotDE/PhantomBotDE/archive/master@{$BUILD}.zip"
	CYNICAL_CUSTOM_BASEURL="https://github.com/TheCynicalTeam/Phantombot-Custom-Scripts/raw/master@{$BUILD}"

	rm -rf nightly-temp
	mkdir -p nightly-download nightly-backup nightly-temp

	echo === Backup ===
	BACKUP_NAME="`date +%Y%m%d-%H%M%S`"
	mkdir -p logs scripts/lang/custom dbbackup addons config
	tar cvzf "nightly-backup/$BACKUP_NAME-conf.tar.gz" --remove-files logs scripts/lang/custom dbbackup addons config
	tar czf "nightly-backup/$BACKUP_NAME-bot.tar.gz" --exclude 'nightly-*' --exclude README.md --remove-files *
	tar czf "nightly-backup/$BACKUP_NAME-bin.tar.gz" nightly-*.sh .git/
	find nightly-backup/ -type f -mtime +7 -print0 | xargs -0r rm -f
	if ((UNINSTALL)) ; then
		rm -rf nightly-download nightly-temp nightly-daemon.fifo nightly-daemon.lock nightly-daemon*.log
		echo Uninstalled Phantombot.
		exit
	fi
	echo

	echo === PhantomBot update ===
	wget -nv "$PHANTOMBOT_URL" -O nightly-download/PhantomBot.zip.temp \
		&& mv -fv nightly-download/PhantomBot.zip.temp nightly-download/PhantomBot.zip
	unzip -q nightly-download/PhantomBot.zip -d nightly-temp/PhantomBot
	find nightly-temp/PhantomBot/*/config -type f -name '*.aac' -print0 | xargs -0r rm -f
	find nightly-temp/PhantomBot/*/config -type f -name '*.ogg' -print0 | xargs -0r rm -f
	cp -pr nightly-temp/PhantomBot/*/* .
	chmod u+x launch*.sh java-runtime-linux/bin/*
	echo

	echo === Translation ===
	wget -nv "$PHANTOMBOT_DE_URL" -O nightly-download/PhantomBotDE.zip.temp \
		&& mv -fv nightly-download/PhantomBotDE.zip.temp nightly-download/PhantomBotDE.zip
	unzip -q nightly-download/PhantomBotDE.zip -d nightly-temp/PhantomBotDE
	cp -pr nightly-temp/PhantomBotDE/*/javascript-source/lang/german scripts/lang/
	ln -s german scripts/lang/deutsch
	echo

	echo === Extras ===
	mkdir -p scripts/custom/games scripts/lang/english/custom/games scripts/lang/german/custom/games
	wget -nv "$CYNICAL_CUSTOM_BASEURL/custom/games/challengeSystem/challengeSystem.js" \
			-O nightly-download/challengeSystem.js.temp \
		&& mv -fv nightly-download/challengeSystem.js.temp nightly-download/challengeSystem.js
	cp -pr nightly-download/challengeSystem.js scripts/custom/games/challengeSystem.js
	wget -nv "$CYNICAL_CUSTOM_BASEURL/lang/english/custom/games/games-challengeSystem.js" \
			-O nightly-download/games-challengeSystem.en.js.temp \
		&& mv -fv nightly-download/games-challengeSystem.en.js.temp nightly-download/games-challengeSystem.en.js
	cp -pr nightly-download/games-challengeSystem.en.js scripts/lang/english/custom/games/games-challengeSystem.js
#	wget -nv "$CYNICAL_CUSTOM_BASEURL/lang/german/custom/games/games-challengeSystem.js" \
#			-O nightly-download/games-challengeSystem.de.js.temp \
#		&& mv -fv nightly-download/games-challengeSystem.de.js.temp nightly-download/games-challengeSystem.de.js
#	cp -pr nightly-download/games-challengeSystem.de.js scripts/lang/german/custom/games/games-challengeSystem.js
	echo

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
