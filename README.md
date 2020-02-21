# PhantomBot Nighty Updater & Launcher

Scripts to download nightly releases of PhantomBot (including translations and extra stuff). **This script will not work on Windows, except using WSL**.

The deamon launcher is supposed to be called via cron. By default it will update weeky and will redirect the input to a FIFO, so it's possible to execute commands. The script will self-update before running.

## Scripts
- `nightly-update.sh` will just update the bot to the latest nightly
- `nightly-daemon.sh` will update once a week and launch the bot with a FIFO

## Downloaded projects
* [PhantomBot](https://github.com/PhantomBot/PhantomBot) - downloaded from the [Nightly](https://github.com/PhantomBot/nightly-build) release (Linux verion).
* [PhantomBotDE](https://github.com/PhantomBotDE/PhantomBotDE) - only the scripts in *javascript-source/lang*.
* [TheCynicalTeam/Phantombot-Custom-Scripts](https://github.com/TheCynicalTeam/Phantombot-Custom-Scripts) - *challengeSystem.js* including lang files.
* Occasionally patch files from pull requests will be downloaded and applied to fix critical bugs.

## Prerequisites
- The usual stuff that comes with Linux/Bash.
- git
- wget
- unzip

## Installation
Git clone this repository or download `nightly-update.sh`. Then, run `nightly-update.sh`. You can setup PhantomBot with `launch.sh`. Alternatively copy an existing configuration over.

After the initial setup you can either keep using `launch.sh` to run PhantomBot and manually update whenever you want using `nightly-update.sh`, or you can use `nightly-daemon.sh`, which will auto-update and launch the bot.

## Running the bot as a daemon
`nightly-daemon.sh` will redirect all output to a FIFO, so it's best to run it in the background. The script also ensures that it's only run once and offers an interface to execute commands. If the bot is running, the arguments to `nightly-daemon.sh` will be used as a command.

Here is a sample crontab file, assuming PhantomBot is installed at */opt/phantombot*:
```crontab
*/5 * * * *  phantombot /opt/phantombot/nightly-daemon.sh --silent &
0   6 * * *  phantombot /opt/phantombot/nightly-daemon.sh --silent exit
```

Options:
* `--silent`: Omit all output
* `-- build <date>`: Updates to the given date instead of the default.
  * To update daily, use `--build today`.
* ` --when-idle`: The command will only be executed when the bot has been idle for a while.
  * At the moment idle means that *pointSystem* has been inactive for an hour.
  * If *pointSystem* is disabled, the command will always be executed.
  * If the bot awards offline points, the bot may never count as idle.
