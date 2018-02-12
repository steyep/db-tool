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

  # Run pre_dump hooks.
  source_hooks 'pre_dump'

  [[ "$ENVIRONMENT" == "local" ]] && {
    make_backup $PROJECT
    return $?
  }

  file="${dumpfolder}/${project}-${environment}-$(date +%Y%m%d).gz"

  [[ "$ENVIRONMENT" == "prod" ]] &&
    ssh ${remotehost} MASTERDB="\$(hostname -s | cut -d'-' -f1)" \; cmd="\$(grep mysqldump /usr/local/bin/sql-update | awk -F'|' '{print \$1}')" \; eval \${cmd} 2>/dev/null | pipe_view | gzip > "${file}" ||
    ssh ${remotehost} "cd /var/www && drush sql-dump" | pipe_view | gzip > "${file}"

  # Run post_dump hooks.
  source_hooks 'post_dump'

  success "Database dumped to \"$file\""
  return 0
}