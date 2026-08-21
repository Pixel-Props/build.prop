#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Start processing directories (default to ./extracted_images)
process_directories "${BASH_SOURCE[0]}" "$1"

# List of files to copy
files_to_copy="nga pixel_experience_ google.xml google_build.xml google_fi.xml adaptivecharging.xml quick_tap.xml"

# Try multiple sysconfig source locations
sysconfig_src=""
for candidate in \
  "$dir/extracted/product/etc/sysconfig" \
  "$dir/extracted/system/product/etc/sysconfig" \
  "$dir/extracted/system/system/etc/sysconfig" \
  "$dir/extracted/system_ext/etc/sysconfig"
do
  if [ -d "$candidate" ] && [ -n "$(ls -A "$candidate"/*.xml 2>/dev/null)" ]; then
    sysconfig_src="$candidate"
    break
  fi
done

if [ -z "$sysconfig_src" ]; then
  print_message "No sysconfig directory found with XML files, skipping…" warning
  exit 0
fi

# Copy specific files
copy_specific_files "$sysconfig_src" "$dir/system/product/etc/sysconfig/" "$files_to_copy"
