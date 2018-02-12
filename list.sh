#! /bin/sh
list_configs() {
  find $configfolder -not -path '*/\.*' -not -path '*/hooks/*' -mindepth 1 -not -name '*.*' -exec sh -c '
  line=$(echo "$0" | sed s-$1/--);
  [[ "$line" != "default" && "$line" != "hooks" ]] && echo "${2}${line}${3}" | sed s#.*/#\ –\ #
  ' {} $configfolder ${BLUE} ${NC} \;
}