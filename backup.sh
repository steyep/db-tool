#! /bin/sh
make_backup() {
	# Check for project
	[[ ! "$PROJECT" ]] && {
		error "You must specify a project";
		list_projects;
		exit 1;
	}
	local orig_dir=${PWD}

	cat > $configfolder/$PROJECT/local <<-END_CONFIG
	project="$project"
	environment="local"
	database="$database"
	remotehost=""
	solr_core=""
	uri=""
	site_root="$site_root"
	dumpfolder="$dumpfolder"
	END_CONFIG

	cd $site_root
	file="${dumpfolder}/${PROJECT}-local-$(date +%Y%m%d).gz"
	drush sql-dump | pipe_view | gzip > "${file}"
	cd $orig_dir
	success "Database backed up to \"$file\""
	return 0
}