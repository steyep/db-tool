#! /bin/sh

function add_project() {
	# If there is a default configuration available, load those settings.
	# [[ "$defaultconfig" == "1" ]] &&  source $configfolder/default
	clear
	local project="$PROJECT"
	local environment="$ENVIRONMENT"
	local host
	local use_solr
	local solr
	local path
	local dumps
	local site_uri

	[[ ! "$project" ]] && read -p "Enter project name: " project

	# See if a project configuration already exists for this project
	if [[ ! "$PROJECT_CONFIG" ]]; then
		database="$project"
		unset remotehost
		unset uri
	fi

	[[ ! "$environment" ]] && read -p "Enter environment name [staging]: " environment
	environment=${environment:-staging}

	local database_default=${database:-$project}
	database_default=${database_default//-/_}
	read -p "Enter database name [$database_default]: " database

	read -p "SSH shortcut (leave blank if N/A): " ssh_shortcut
	if [[ ! "$ssh_shortcut" ]]; then
		host_default="$(echo "$host_default" | sed -E s/-\[^\.\]+\./-$environment./)"
		read -p "Enter remote host: " host
	fi

	read -p "Configure a solr core for $project [y/n]: " use_solr
	if [[ "$use_solr" =~ [yY] ]]; then
		read -p "Enter url to Solr core [$solr_core]: " solr
		solr=${solr:-$solr_core}
		local uri_default="${uri:-$project.dev}"
		read -p "Enter local site uri [$uri_default]: " site_uri
		site_uri=${site_uri:-$uri}
	fi

	if [[ "$defaultconfig" == "1" ]]; then
		read -p "Set $project as default for $(basename $0)? [y/n]: " set_default
		[[ "$set_default" =~ [yY] ]] && defaultconfig=0
	fi

	local site_root_default=$HOME/Sites/$project
	read -p "Enter path to local site root [$site_root_default]: " path
	read -p "Enter path to store db dumps [$dumpfolder]: " dumps

	local settings=$(cat <<-SETTINGS
	project="$project"
	environment="$environment"
	database="${database:-$database_default}"
	remotehost="${ssh_shortcut:-$host}"
	solr_core="${solr}"
	uri="${site_uri}"
	site_root="${path:-$site_root_default}"
	dumpfolder="${dumps:-$dumpfolder}"
	SETTINGS
	)

	test ! -d $configfolder/$project && mkdir -p $configfolder/$project
	echo "$settings" > $configfolder/$project/$environment
	
	if [[ "$defaultconfig" == "0" ]]; then
		echo "$settings" > $configfolder/default
	fi
	success "Successfully added $project"
	exit 0
}