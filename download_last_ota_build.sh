#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

if [ -z "$1" ]; then
  print_message "No ota device name provided to be downloaded" error
  return 1
fi

# Get download link from the latest build that is not mobile carrier restricted {33} chars to be expected.
last_build_url=$(curl -Ls 'https://developers.google.cn/android/ota?partial=1' | grep -Eo "\"(\S+$1\S{33})?zip" | tail -1 | tr -d \")
print_message "Downloading ($1) \"$last_build_url\"..." debug
wget --tries=inf --show-progress -q "$last_build_url"
print_message "Done you can now extract/dump the image" info
