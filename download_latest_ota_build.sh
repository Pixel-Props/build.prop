#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

if [ -z "$1" ]; then
  print_message "No OTA device name provided" error
  exit 1
fi

print_message "Downloading OTA builds for the following devices: $(
  IFS=,
  echo "${*:1}"
)…" info
unset IFS

# Make sure download directory exists
[ ! -d ./dl ] && mkdir dl

# Build a list of URL to be downloaded
BUILD_URL_LIST=()

# This script downloads the latest OTA build for a list of devices.
# The device names are passed as arguments to the script.
for device_name in "$@"; do # Loop over each argument (device name)

  # Extract any possible Android version from the device name
  android_version=$(echo "$device_name" | grep -oP '\K\d+')

  # Check if the Android version is between 14 and 15, otherwise fallback to 14
  [[ $android_version -ge 14 && $android_version -le 15 ]] || android_version=14

  # Remove any numbers from the device name
  device_name=${device_name//[^[:alpha:]_]/}

  # Check if the device name contains "_beta"
  if [[ $device_name == *_beta* ]]; then
    # If it does, fetch the URL of the latest beta build for the device from the beta builds page
    # The grep command extracts the URL of the zip file for the device
    # The tail command gets the last URL in the list (the latest build)
    last_build_url=$(curl -b "devsite_wall_acks=nexus-ota-tos" -Ls "https://developer.android.com/about/versions/$android_version/download-ota?partial=1" | grep -oP "https://\S+${device_name}\S+\.zip" | tail -1)
  else
    # If the device name does not contain "_beta", fetch the URL of the latest non-beta build for the device from the non-beta builds page
    # The grep command extracts the URL of the zip file for the device
    # The sed command removes unicode strings
    # The awk command filters out lines with more than one comma (ignoring custom locked builds)
    # The tail command gets the last URL in the list (the latest build)
    last_build_url=$(curl -b "devsite_wall_acks=nexus-ota-tos" -Ls 'https://developers.google.com/android/ota?partial=1' | grep -oP "\d+(\.\d+)+ \([^)]+\).*?https://\S+${device_name}\S+zip" | sed -n 's/\\u003c\/td\\u003e\\n    \\u003ctd\\u003e\\u003ca href=\\"/ /p' | awk -F',' 'NF<=2' | tail -1 | grep -Eo "(https\S+)")
  fi

  if [[ -n $last_build_url ]]; then
    # Print a message indicating that the download is starting
    print_message "Downloading OTA build for ${device_name^} (\"$last_build_url\")…" debug

    # Add the URL to the list.
    BUILD_URL_LIST+=("$last_build_url")

    # Download the build using wget
    # wget --tries=inf --show-progress -P ./dl -q "$last_build_url" &
  fi
done

# Download the build using aria2
aria2c -Z -m0 -x16 -s16 -j16 --enable-rpc=false --optimize-concurrent-downloads=true --disable-ipv6=true --allow-overwrite=true --remove-control-file=true --always-resume=false --download-result=hide --summary-interval=0 -d ./dl "${BUILD_URL_LIST[@]}"
print_message "Download complete" info
