#! /bin/sh
function source_hooks() {
  local hook="$1"

  # Establish hook directory.
  local hook_dir=$configfolder/hooks
  test -d "${hook_dir}" || { test -d "${SCRIPT_DIR}/hooks" && cp -r "${SCRIPT_DIR}/hooks" "$configfolder" || mkdir -p "${hook_dir}"; }

  # Source global hooks
  local global_hook="${hook_dir}/hook_${hook}"

  test -f "$global_hook" && source "$global_hook"

  if [[ "$PROJECT" ]]; then
    local project_hook="${hook_dir}/${PROJECT}_${hook}"
    test -f "$project_hook" && source "$project_hook"
  fi
}