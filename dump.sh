#! /bin/sh
get_dump() {
  # Check for project
  [[ ! "$PROJECT" ]] && {
    error "You must specify a project";
    list_projects;
    exit 1;
  }

  # Check for environment
  [[ ! "$ENVIRONMENT" ]] && {
    error "You must specify an environment";
    list_environments;
    exit 1;
  }

  [[ "$ENVIRONMENT" == "local" ]] && {
    make_backup $PROJECT
    return $?
  }

  file="${dumpfolder}/${project}-${environment}-$(date +%Y%m%d).gz"
  ssh ${remotehost} "cd /var/www && drush sql-dump" | pipe_view | gzip > "${file}"
  success "Database dumped to \"$file\""
  return 0
}