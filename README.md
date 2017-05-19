# db
Utility for managing SQL databases.

### Installation:
* Clone the repo
* Run the `install.sh` script

### Usage:
```
Usage: $SCRIPT <action> <argument> [options]

  The following actions are supported:
    add [project] [env]                : Configure a new project.
    remove <project> [env]             : Remove all of a project's configurations.
                                       : If an environment is specified, only the specified
                                       : environment will be removed.
    import <project> [env]             : Imports the most recent database dump locally.
    dump <project> <env>               : Gets a database dump from the configured project's
                                       : specified environment.
    refresh <project> <env>            : Gets a fresh databse dump and imports it locally.
    backup <project>                   : Make a local backup of a project's database.
```