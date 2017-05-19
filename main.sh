#! /bin/sh
SCRIPT="$0"
while test -L "$SCRIPT"; do
  SCRIPT="$(readlink "$SCRIPT")"
done

error() {
  local message="$1";
  echo ${RED}'Error: '${NC}${message};
  echo
  return 1;
}

pushd $(dirname "$SCRIPT") > /dev/null
  for module in config {add-project,remove-project,dump,import,backup}.sh; do
    test -f ${PWD}/${module} && source ${PWD}/${module} || error "Unable to load $module"
  done
popd > /dev/null

SCRIPT=$(basename "$0")
ACTION="$1"
PROJECT="$2"
ENVIRONMENT="$3"

pipe_view() {
  hash pv &>/dev/null && cat /dev/stdin | pv "$@" || cat /dev/stdin
}

success() {
	STATUS=0
	local message="$1"
  echo
	echo '\033[0;32m\xE2\x9C\x94\033[0m '"$message"
}

load_client_config() {
	local client="$1"
	local environment="$2"
	# See if a project configuration already exists for this project
	local client_file=(`find $configfolder/$client -not -path '*/\.*' -type f -name "*${environment}" 2>/dev/null`)
	# Load it's settings as defaults if so:
	[[ "$client_file" && -f $client_file ]] && echo "$client_file"
}

list_projects() {
	local available_projects=$(ls $configfolder | grep -v default)
	[[ "$available_projects" ]] && echo "Available Projects:\n$available_projects"
}

list_environments() {
	local available_environments=$(ls $projectfolder)
	[[ "$available_environments" ]] && echo "Available Environments:\n$available_environments"
}

# Validate configfolder
test -d $configfolder || mkdir -p $configfolder
test -f $configfolder/default && defaultconfig=1

[[ "$ACTION" == "backup" ]] && unset ENVIRONMENT

# Validate PROJECT
if [[ "$PROJECT" ]]; then
	projectfolder="$(find $configfolder -maxdepth 1 -type d -name $PROJECT 2>/dev/null)"
	if [[ ! "$projectfolder" && "$ACTION" != "add" ]]; then
	  error "\"$PROJECT\" is not a valid project"
		list_projects
	  exit 1
	fi
fi

# Validate ENVIRONMENT
if [[ "$ENVIRONMENT" ]]; then
	available_environments=$(ls $projectfolder)
  if [[ ! "$(echo "$available_environments" | grep -E "^${ENVIRONMENT}$")" && "$ACTION" != "add" ]]; then
    error "\"$ENVIRONMENT\" is not a valid environment"
    list_environments
    exit 1
  fi
fi

# set PROJECT_CONFIG
PROJECT_CONFIG=$(load_client_config "$PROJECT" "$ENVIRONMENT")
if [[ "$ACTION" != "add" ]]; then
	[[ "$PROJECT_CONFIG" && -f $PROJECT_CONFIG ]] && source "$PROJECT_CONFIG" || {
		error "Problem with project config: $PROJECT_CONFIG";
		exit 1;
	}
fi

show_menu() {
	cat <<-END_MENU
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

	END_MENU
}

case "$ACTION" in
	add) add_project ;;
	remove|rm) remove ;;
	import) get_import ;;
	dump) get_dump ;;
	refresh) get_dump && get_import ;;
	backup) make_backup ;;
	*) show_menu && exit ;;
esac
