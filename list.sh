#! /bin/sh
list_configs() {
  find $configfolder -not -path '*/\.*' -mindepth 1 -exec sh -c '
  line=$(echo "$0" | sed s-$1/--);
  [[ "$line" != "default" ]] && echo "${2}${line}${3}" | sed s#.*/#\ –\ #
  ' {} $configfolder ${BLUE} ${NC} \;
}