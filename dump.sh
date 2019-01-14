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
		# Run pre_dump hooks.
		source_hooks 'pre_dump'
    make_backup $PROJECT
    return $?
  }

  file="${dumpfolder}/${project}-${environment}-$(date +%Y%m%d).gz"

	# This command can be modified by altering ${dump_cmd} in a pre_dump hook.
	read -r -d '' dump_cmd <<-'CMD'
		drush --root=/var/www sql-dump
	CMD

	# Run pre_dump hooks.
  source_hooks 'pre_dump'

	cmd="$(cat <<-DUMP_CMD
		ssh $remotehost <<'ENDSSH'
		$dump_cmd
		ENDSSH
	DUMP_CMD
	)"

	eval "$cmd" 2> /dev/null | pipe_view | gzip > "${file}"

  # Run post_dump hooks.
  source_hooks 'post_dump'

  success "Database dumped to \"$file\""
  return 0
}