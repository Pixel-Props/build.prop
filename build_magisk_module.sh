#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Load data from script base path if no directory were specified
[ -n "$1" ] && dir=$1 || {
	for dir in ./extracted_images/*; do # List directory ./*
		if [ -d "$dir" ]; then             # Check if it is a directory
			dir=${dir%*/}                     # Remove last /
			print_message "Processing \"${dir##*/}\"" debug

			# Build system.prop
			./"${BASH_SOURCE[0]}" "$dir"
		fi
	done
	exit 1
}

# Extract device information
result_base_name=$(basename "$dir")
vendor_path="$dir/extracted/vendor/build.prop"
system_path="$dir/extracted/system/system/build.prop"

device_name=$(grep_prop "ro.product.model" "$system_path")
device_build_id=$(grep_prop "ro.build.id" "$system_path")
device_code_name=$(grep_prop "ro.product.vendor.name" "$vendor_path")
device_build_android_version=$(grep_prop "ro.vendor.build.version.release" "$vendor_path")
device_build_security_patch=$(grep_prop "ro.vendor.build.security_patch" "$vendor_path")
device_code_name_title=${device_code_name^}

# Construct the base name
base_name=${device_code_name^}.A$device_build_android_version.$(date -d "$device_build_security_patch" '+%y%m%d')

# Prepare the result directory
mkdir -p "result/$result_base_name"
cp "$dir"/{module,system}.prop "result/$result_base_name/"
cp -r ./magisk_module_files/* "result/$result_base_name/"

# Create the zip file
cd "result/$result_base_name" || exit 1
zip -r -q "../../$base_name".zip .
cd ../..

print_message "Module saved to $base_name.zip" info

# Save the build information (only for the latest build)
if [ -n "$GITHUB_OUTPUT" ]; then
	{
		echo "module_base_name=$base_name"
		echo "module_hash=$(sha256sum "$base_name.zip" | awk '{print $1}')"
		echo "device_name=$device_name"
		echo "device_code_name_title=$device_code_name_title"
		echo "device_build_id=$device_build_id"
		echo "device_build_android_version=$device_build_android_version"
		echo "device_build_security_patch=$device_build_security_patch"
	} >>"$GITHUB_OUTPUT"
fi
