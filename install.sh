#! /bin/sh
pushd $(dirname "$0") > /dev/null
  script_dir="$PWD"
popd > /dev/null

destination=
for bin in $HOME/bin /usr/local/bin /usr/bin; do
  test -d $bin -a -w $bin || continue
  for location in ${PATH//:/ }; do
    [[ $location == $bin ]] && { destination=$bin; break 2; }
  done
done

if [[ ! "$destination" ]]; then
  echo "ERROR: Unable to locate a writeable directory on your \$PATH"
  echo "       Ensure /usr/local/bin is on your \$PATH variable"
  echo "       Or try running the install script with \`sudo\` privileges."
  exit 1
fi

echo "Assigning executable privileges to the script"
chmod +x "$script_dir/main.sh"

echo "Creating symlink at $destination"
ln -Fis "$script_dir/main.sh" $destination/db

echo "Finished!"