#! /bin/sh
get_import() {
  # Check for project
  [[ ! "$PROJECT" ]] && {
    error "You must specify a project";
    list_projects;
    exit 1;
  }

  if [ -z $dbuser ]; then
    read -p "Enter MySQL database username: " dbuser
    read -p "Enter MySQL database password: " dbpass
  fi

  # Run pre_import hooks.
  source_hooks 'pre_import'

  recent_dump=(`find $dumpfolder -type f -name "${project}-${ENVIRONMENT}*.gz" -exec ls -t {} +`)
  [[ ! "$recent_dump" || ! -f "$recent_dump" ]] && {
    error "Unable to locate a recent ${ENVIRONMENT} database dump for $project";
    exit 1;
  }
  local orig_dir="$PWD"
  if [[ "$(pgrep httpd)" && "$(ls /tmp | grep 'mysql.sock')" ]]; then
    cd $site_root

    # Create database if it doesn't already exist
    $mysql_wrapper -e"create database if not exists $database;"

    # Create a settings.php file if this is a new site.
    if [ ! -f $site_root/sites/default/settings.php ]; then
      test -f $SCRIPT_DIR/settings.php && cp $SCRIPT_DIR/settings.php $site_root/sites/default/
    fi

    echo "Dropping all database tables..."
    drush sql-drop -y

    gzip -dc $recent_dump | pipe_view --progress --size $(gzip -l $recent_dump | sed -n 2p | awk '{print $2}') --name "Importing $(basename $recent_dump)... " | $mysql_wrapper $database

    # Run post_import hooks.
    source_hooks 'post_import'

    # If memcached is running, flush it.
    if [[ "$(pgrep memcached)" ]]; then
      echo "Flushing memcache..."
      echo "flush_all" | nc localhost 11211 &> /dev/null
      echo
    fi

    # Set proper apache solr instance
    if [[ "$solr_core" ]]; then
      echo "Setting up the proper apache solr instance..."
      drush sqlq "UPDATE apachesolr_environment SET url = \"$solr_core\" WHERE env_id = 'solr'" &>/dev/null
      # Reindex apache solr.
      if [[ "$(wget $solr_core --timeout 30 -O - 2>&1 | grep connected)" ]]; then
        echo "Delete and reindex apache solr..."
        drush solr-delete-index
        drush --uri=$uri solr-mark-all
        drush --uri=$uri solr-index
      else
        error "Unable to reach $solr_core"
      fi
      echo
    fi

    # Clear Drupal caches.
    echo "Clearing Drupal caches"
    drush cc all

    cd $orig_dir
    success "$database imported"
  else
    error "Unable to import db"
    error "Apache and MySQL must be running"
  fi
  return $STATUS
}