# PhantomBot Nighty Updater & Launcher

Scripts to download nightly releases of PhantomBot.

The daemon launcher is supposed to be called via cron. By default it will update weeky and will redirect the input to a FIFO, so it's possible to execute commands. The script will self-update before running.

## Scripts
- `nightly-update.sh` will just update the bot to the latest nightly
- `nightly-daemon.sh` will update once a week and launch the bot with a FIFO

## Used sources
* [PhantomBot](https://github.com/PhantomBot/PhantomBot) - downloaded from the [nightly release](https://github.com/PhantomBot/nightly-build) (Linux version), including the JRE.
* Occasionally patch files from pull requests will be downloaded and applied to fix critical bugs.

## Prerequisites
- bash
- tar
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
* `--build <date>`: Updates to the given date
* `--no-runtime`: Don't download Java runtime
* `--runtime <runtime>`: Runtime to download - `lin` (default), `arm64`, `mac` or `win`
