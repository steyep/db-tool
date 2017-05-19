#! /bin/sh

remove() {
  [[ ! "$PROJECT" ]] && {
    error "You must specify a project";
    list_projects;
  }
  if [[ "$ENVIRONMENT" ]]; then
      find $projectfolder -maxdepth 1 -type f -name "$ENVIRONMENT" -delete
      [[ ! "$(list_environments)" ]] && rm -rf "$projectfolder"
  else
    test -d "$projectfolder" && rm -rf "$projectfolder"
  fi
  success "Removed $project $ENVIRONMENT"
}