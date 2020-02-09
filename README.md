# PhantomBot Nighty Updater & Launcher

Scripts to download nightly releases of PhantomBot (including translations and extra stuff).

The deamon launcher is supposed to be called via cron. By default it will update weeky and will redirect the input to a FIFO, so it's possible to execute commands.

## Scripts
- `nightly-update.sh` will just update the bot to the latest nightly
- `nightly-daemon.sh` will update once a week and launch the bot with a fifo
