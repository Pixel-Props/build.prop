#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

if [ -z "$1" ]; then
  print_message "No OTA device name provided" error
  exit 1
fi

print_message "Downloading OTA builds for the following devices: $(IFS=, ; echo "${*:1}")..." info

# Get download link from the latest build that is not mobile carrier restricted {33} chars to be expected.
for device_name in "$@"; do # Allow multiple arguments
  # last_build_url=$(curl -b "devsite_wall_acks=nexus-ota-tos" -Ls 'https://developers.google.com/android/ota?partial=1' | grep -Eo "\"(\S+${device_name}\S+)?zip" | tail -1 | tr -d \")
  # Could be unstable but fix for stable OTA no carrier.
  last_build_url=$(curl -b "devsite_wall_acks=nexus-ota-tos" -Ls 'https://developers.google.com/android/ota?partial=1' | grep -oP '\d+(\.\d+)+ \([^)]+\).*?https://\S+husky\S+zip' | sed -n 's/\\u003c\/td\\u003e\\n    \\u003ctd\\u003e\\u003ca href=\\"/ /p' | awk '!/AT|Verizon|T-Mobile|US-Emerging|carrier|KDDI/' | tail -1 | grep -Eo "(https\S+)")
  print_message "Downloading OTA build for ${device_name^} (\"$last_build_url\")..." debug
  wget --tries=inf --show-progress -q "$last_build_url"
done

print_message "Download complete" info
