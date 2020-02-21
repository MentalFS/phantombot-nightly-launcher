#!/bin/bash
set +e
{ for COMMAND in git wget unzip tar sed; do
	which "$COMMAND" >/dev/null || { echo "Could not find $COMMAND in PATH." 1>&2; exit 1; } ; done }
cd "$(dirname "$(readlink -f "$0")")"

function update() {
	PHANTOMBOT_URL="https://github.com/PhantomBot/nightly-build/raw/master@{$BUILD}/PhantomBot-nightly-$ARCH.zip"
	PHANTOMBOT_DE_URL="https://github.com/PhantomBotDE/PhantomBotDE/archive/master@{$BUILD}.zip"
	CYNICAL_CUSTOM_BASEURL="https://github.com/TheCynicalTeam/Phantombot-Custom-Scripts/raw/master@{$BUILD}"
	PATCHES+=()

	rm -rf nightly-temp
	mkdir -p nightly-download nightly-backup nightly-temp || exit 1

	echo === Backup ===
	BOT_NAME="$(sed -n 's/^ *user= *\([^ ]*\) */\1/p' config/botlogin.txt 2>/dev/null)"
	test -z "$BOT_NAME" && BOT_NAME="PhantomBot"
	BACKUP_NAME="$BOT_NAME-`date +%Y%m%d.%H%M%S`"
	mkdir -p logs scripts/lang/custom dbbackup addons config
	tar cvzf "nightly-backup/$BACKUP_NAME-data.tar.gz" --remove-files ./logs ./scripts/lang/custom ./dbbackup ./addons ./config || exit 1
	tar czf "nightly-backup/$BACKUP_NAME-binaries.tar.gz" --exclude './nightly-*' --exclude ./README.md --exclude ./LICENSE --remove-files ./*
	tar czf "nightly-backup/$BACKUP_NAME-launcher.tar.gz" ./nightly-*.sh ./README.md ./LICENSE ./.git/ ./.gitignore
	if ((UNINSTALL)) ; then
		rm -rf nightly-download nightly-temp nightly-daemon.fifo nightly-daemon.lock nightly-daemon*.log
		echo Uninstalled Phantombot.
		exit
	fi
	echo

	echo === PhantomBot update ===
	download "$PHANTOMBOT_URL" nightly-download/PhantomBot.zip
	unzip -q nightly-download/PhantomBot.zip -d nightly-temp/PhantomBot
	find nightly-temp/PhantomBot/*/config -type f -name '*.aac' -print0 | xargs -0r rm -f
	find nightly-temp/PhantomBot/*/config -type f -name '*.ogg' -print0 | xargs -0r rm -f
	cp -pr nightly-temp/PhantomBot/*/* .
	chmod u+x launch*.sh java-runtime-linux/bin/*
	echo

	echo === Translation ===
	download "$PHANTOMBOT_DE_URL" nightly-download/PhantomBotDE.zip
	unzip -q nightly-download/PhantomBotDE.zip -d nightly-temp/PhantomBotDE
	cp -pr nightly-temp/PhantomBotDE/*/javascript-source/lang/german scripts/lang/
	ln -s german scripts/lang/deutsch
	echo

	echo === Challenge ===
	mkdir -p scripts/custom/games scripts/lang/english/custom/games scripts/lang/german/custom/games
	download "$CYNICAL_CUSTOM_BASEURL/custom/games/challengeSystem/challengeSystem.js"  nightly-download/challengeSystem.js
	cp -pr nightly-download/challengeSystem.js scripts/custom/games/challengeSystem.js
	download "$CYNICAL_CUSTOM_BASEURL/lang/english/custom/games/games-challengeSystem.js" nightly-download/games-challengeSystem.en.js
	cp -pr nightly-download/games-challengeSystem.en.js scripts/lang/english/custom/games/games-challengeSystem.js
#	download "$CYNICAL_CUSTOM_BASEURL/lang/german/custom/games/games-challengeSystem.js" nightly-download/games-challengeSystem.de.js
#	cp -pr nightly-download/games-challengeSystem.de.js scripts/lang/german/custom/games/games-challengeSystem.js
	echo

	for P in "${!PATCHES[@]}" ; do
		echo === Patch $P ===
		download "${PATCHES[$P]}" "nightly-download/hotfix_$P.patch"
		sed 's:/javascript-source/:/scripts/:g' -i "nightly-download/hotfix_$P.patch"
		git apply --stat --apply "nightly-download/hotfix_$P.patch" | echo "WARNING - PATCH ERROR - Probably already fixed."
		echo
	done

	echo === Finish ===
	echo Data/Configuration:
	tar xzf "nightly-backup/$BACKUP_NAME-data.tar.gz" || exit 1
	tar tzf "nightly-backup/$BACKUP_NAME-data.tar.gz" | sed -n 's:^./::;s:.*/$:\0:p' | sort | xargs -rd '\n' du -sch
	echo
	echo Backups:
	find nightly-backup/ -type f -mtime +15 -print0 | xargs -0r rm -f
	du -sch nightly-backup/$BACKUP_NAME-*
	echo
	echo Caches:
	find nightly-download -type f -mtime +1 -print0 | xargs -0r rm -f
	rm -rf nightly-temp
	du -sch nightly-*/
	echo
	echo Installation:
	du -sh "$PWD"
}

function download() {
	URL="$1"
	TARGET="$2"
	wget -nv "${URL}" -O "${TARGET}.temp" && mv -fv "${TARGET}.temp" "${TARGET}"
}

function pull() {
	echo === Self-update ===
	if [ ! -d .git ] ; then
		git init .
		git remote add -t \* -f origin "https://github.com/MentalFS/PhantomBot-Nightly.git"
		git checkout master --force
	fi
	git --no-pager pull || exit 1
	git checkout --force || exit 1
	echo
	{ exec "$(readlink -f "$0")" --no-pull "$@"; exit 1; }
}

function read_parameters() {
	BUILD=today
	NO_PULL=0
	UNINSTALL=0
	CLEANUP=1

	ARCH=lin
	[[ "$MACHTYPE" != "x86_64"* ]] && ARCH=arm
	[[ "$OSTYPE" == "darwin"* ]] && ARCH=mac

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
