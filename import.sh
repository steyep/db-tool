#! /bin/sh
get_import() {
  # Check for project
  [[ ! "$PROJECT" ]] && {
    error "You must specify a project";
    list_projects;
    exit 1;
  }

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
    mysql -u root -proot -e"create database if not exists $database;"

    # Create a settings.php file if this is a new site.
    if [ ! -f $site_root/sites/default/settings.php ]; then
      test -f $SCRIPT_DIR/settings.php && cp $SCRIPT_DIR/settings.php $site_root/sites/default/
    fi

    echo "Dropping all database tables..."
    drush sql-drop -y

    gzip -dc $recent_dump | pipe_view --progress --size $(gzip -l $recent_dump | sed -n 2p | awk '{print $2}') --name "Importing $(basename $recent_dump)... " | mysql -u root -proot $database

    drupal_version=$(drush st drupal-version 2>/dev/null | awk '{ split($4,a,"."); printf a[1] }')

    if (( $drupal_version > 6 )); then
      message_fixer="$(drush pml --type=Module --no-core --pipe 2>/dev/null | grep module_missing_message_fixer)"

      # Enable module_missing_message_fixer
      echo "Enabling module_missing_message_fixer..."
      drush en module_missing_message_fixer -y &>/dev/null
      echo

      # Remove references to missing modules
      fix_references=0
      for module in $(drush mmmfl --no-field-labels --fields=name 2>/dev/null); do
        fix_references=1
        echo "Removing references to ${module}..."
        drush mmmff $module &> /dev/null
      done
      [[ "$fix_references" == "1" ]] && echo

      # Disable simplesaml
      for module in $(drush pml --type=Module --status=Enabled --no-core --pipe 2>/dev/null | grep simplesaml); do
        echo "Disabling SimpleSAML..."
        drush dis $module -y 2>/dev/null
        echo
      done
    fi

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

    # If Drupal version is 7 or 8, install the admin theme
    if (( $drupal_version > 6 )); then
      echo "Setting admin theme..."
      drush drupal-directory $admin_theme &> /dev/null || drush dl $admin_theme_project 2>/dev/null
      drush en $admin_theme -y 2>/dev/null
      drush vset admin_theme $admin_theme 2>/dev/null
      echo
    fi

    # Enable devel
    echo "Enabling devel..."
    drush en devel -y 2>/dev/null
    echo

    # Enable Reroute Email
    echo "Enabling reroute_email..."
    drush en reroute_email -y 2>/dev/null
    drush vset reroute_email_address ''
    drush vset reroute_email_enable 1
    echo

    # Disable Autologout.
    echo "Disabling autologout..."
    drush dis autologout -y 2>/dev/null
    echo

    # Remove module_missing_message_fixer
    if [[ ! "$message_fixer" ]]; then
      module_path="$(drush pmi module_missing_message_fixer 2>/dev/null | grep Path | awk '{print $3}')"
      if [[ "$module_path" ]]; then
        echo "Disabling module_missing_message_fixer..."
        drush dis module_missing_message_fixer -y 2>/dev/null
        echo "Uninstalling module_missing_message_fixer..."
        drush pmu module_missing_message_fixer -y 2>/dev/null
        if [ -d "$module_path" ]; then
          echo "Removing module_missing_message_fixer from project..."
          rm -rf "$module_path"
        else
          error "Unable to remove $module_path"
        fi
        echo
      fi
    fi

    # Clear Drupal caches.
    echo "Clearing Drupal caches"
    drush cc all

    # Run post_import hooks.
    source_hooks 'post_import'

    cd $orig_dir
    success "$database imported"
  else
    error "Unable to import db"
    error "Apache and MySQL must be running"
  fi
  return $STATUS
}