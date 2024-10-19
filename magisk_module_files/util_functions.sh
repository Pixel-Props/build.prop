#!/system/bin/sh

# Function to find build & system properties within a specified directory.
find_prop_files() {
  dir="$1"
  maxdepth="$2"
  maxdepth=${maxdepth:-3}

  find "$dir" -maxdepth "$maxdepth" -type f \( -name 'build.prop' -o -name 'system.prop' \) -print 2>/dev/null
}

# Function to grep a property value from a list of files
grep_prop() {
  PROP="$1"
  shift
  FILES_or_VAR="$@"

  if [ -n "$FILES_or_VAR" ]; then
    echo "$FILES_or_VAR" | grep -m1 "^$PROP=" 2>/dev/null | cut -d= -f2- | head -n 1
  fi
}
