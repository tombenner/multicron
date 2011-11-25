MultiCron
==================================================
A better way to manage cron jobs for applications

Description
-----------

MultiCron allows you to:

* Track a generalized crontab file for an application in a version control system (e.g. git, svn)
* Organize cron jobs across multiple crontab files
* Run the same set of cron jobs for multiple applications/directories

Usage
-----

To use MultiCron you'll need to:

1. Make one or more crontab files
1. Add an entry to your crontab (using `crontab -e`) that runs MultiCron with the appropriate options every minute (don't worry, it's light!)

### Crontab files

The crontab files that MultiCron ingests are exactly like usual crontab files, except that a token can be used that will be replaced by the path(s) specified in `-p` or `app_paths` (see the "Inputs" section below).

    # Run a script every 15 minutes
    */15 * * * * [[APP_PATH]]/path/to/script
    # Delete some old files every day at 4AM and 10PM
    0 4,22 * * * find [[APP_PATH]]/tmp/cache -type f -mtime +2 | xargs rm

### Inputs

MultiCron is a program that takes two inputs: a list of crontab files and, optionally, a list of application paths.  For each application path that's listed, each crontab file will be run with the `[[APP_PATH]]` token being replaced by the path.

The inputs can either be set in program's options or in a config file.

#### Setting the inputs in the program's options

Options

    -p
        The path(s) which will replace the [[APP_PATH]] token.
        Examples:
            -p "/path/to/app1"
            -p "/path/to/app1,/path/to/app2"
    -x
        The path(s) to crontab file(s), separated by commas.
        Examples:
            -x "/path/to/crontab.txt"
            -x "/path/to/crontab1.txt,/path/to/crontab2.txt"

#### Setting the inputs in a config file

Instead of using the `-p` and `-x` options, you can use a config file using the `-c` option:

    /path/to/multicron -c "/path/to/config.sh"

The config file should set two variables:

    # config.sh
    crontab_files="/path/to/crontab1.txt,/path/to/crontab2.txt"
    app_paths="/path/to/app1,/path/to/app2"

_N.B.: The config file is executed, so variables can be used to keep it DRY:_

    # config.sh
    cron="/my/long/path/to/crontabs"
    apps="/my/long/path/to/apps"
    crontab_files="$cron/crontab1.txt,$cron/crontab2.txt,$cron/crontab3.txt"
    app_paths="$apps/app1,$apps/app2,$apps/app3"

### Running MultiCron

To run MultiCron, simply add it to your crontab file (using `crontab -e`) and run it every minute:

    * * * * * /path/to/multicron -c "/path/to/config.txt"

Examples
--------

### A single generalized crontab file for a single application

If your app is in `/path/to/app` and your version-controlled, generalized crontab file is at `/path/to/app/crontabs/crontab.txt`:

    # Run a script every 15 minutes
    */15 * * * * [[APP_PATH]]/path/to/script
    # Delete some old files every day at 4AM and 10PM
    0 4,22 * * * find [[APP_PATH]]/tmp/cache -type f -mtime +2 | xargs rm

In your crontab (using `crontab -e`), you'd add an entry that will run that crontab file, replacing `[[APP_PATH]]` with `"/path/to/app"`

    * * * * * /path/to/multicron -x "/path/to/app/crontabs/crontab.txt" -p "/path/to/app"

### Multiple generalized crontab files for a single application

Roughly the same as above, except that you'd need to list the two crontab files:

    * * * * * /path/to/multicron -x "/path/to/app/crontabs/crontab1.txt,/path/to/app/crontabs/crontab2.txt" -p "/path/to/app"

### A single generalized crontab file for multiple applications

Again, just a slight modification of the line above:

    * * * * * /path/to/multicron -x "/path/to/app/crontabs/crontab.txt" -p "/path/to/app1,/path/to/app2"

### Multiple generalized crontab files for multiple applications

This would run each crontab file once for each application:

    * * * * * /path/to/multicron -x "/path/to/app/crontabs/crontab1.txt,/path/to/app/crontabs/crontab2.txt" -p "/path/to/app1,/path/to/app2"

Development
-----------

If you have any ideas of ways to improve MultiCron, please don't hesitate to shoot me a line!  I can be reached at [my GitHub account](https://github.com/tombenner).