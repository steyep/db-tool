# db
Utility for managing SQL databases.

### Installation:
* Clone the repo
* Run the `install.sh` script

### Usage:
```
Usage: db <action> <argument> [options]

  The following actions are supported:
    list | ls                          : List configured projects/environments.
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

You can define hooks that will be called before/after importing a database and before/after dumping a database:

| Hook file | Description |
| --- | --- |
| `$HOME/db_tool.d/hooks/hook_pre_dump` | Script/commands to be run for every project _before_ dumping a database |
| `$HOME/db_tool.d/hooks/hook_post_dump` | Script/commands to be run for every project _after_ dumping a database |
| `$HOME/db_tool.d/hooks/hook_pre_import` | Script/commands to be run for every project _before_ importing a database |
| `$HOME/db_tool.d/hooks/hook_post_import` | Script/commands to be run for every project _after_ importing a database |

You can define project specific hooks by replacing the `hook` in the file name with the name of the project. `$HOME/db_tool.d/hooks/foo_post_import` will be run after importing **foo**'s database. Global hooks are always run before project specific hooks.