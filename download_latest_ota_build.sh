#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

if [ -z "$1" ]; then
  print_message "No OTA device name provided" error
  return 1
fi

print_message "Downloading OTA builds for the following devices: $(IFS=, ; echo "${@[*]}")..." info

# Get download link from the latest build that is not mobile carrier restricted {33} chars to be expected.
for device_name in "$@"; do # Allow multiple arguments
  last_build_url=$(curl -Ls 'https://developers.google.cn/android/ota?partial=1' | grep -Eo "\"(\S+${device_name}\S{33})?zip" | tail -1 | tr -d \")
  print_message "Downloading OTA build for ${device_name^} (\"$last_build_url\")..." debug
  wget --tries=inf --show-progress -q "$last_build_url"
done

print_message "Download complete" info
