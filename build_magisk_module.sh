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

# Current basename
base_name=$(basename "$dir")
echo $base_name
# Define the props path
declare EXT_PROP_FILES=$(find_prop_files "$dir")
# Store the content of all prop files in a variable
declare EXT_PROP_CONTENT=$(cat $EXT_PROP_FILES)

device_name=$(grep_prop "ro.product.model" "$EXT_PROP_CONTENT")
device_build_id=$(grep_prop "ro.build.id" "$EXT_PROP_CONTENT")
device_codename=$(grep_prop "ro.product.vendor.name" "$EXT_PROP_CONTENT")
device_build_description=$(grep_prop "ro.build.description" "$EXT_PROP_CONTENT")
device_build_android_version=$(grep_prop "ro.vendor.build.version.release" "$EXT_PROP_CONTENT")
device_build_security_patch=$(grep_prop "ro.vendor.build.security_patch" "$EXT_PROP_CONTENT")
device_codename=${device_codename^}

# Construct the base name
base_name="${device_codename}_$device_build_id"

if [ ! -d "result/$base_name" ]; then
    mkdir -p "result/$base_name"
fi

echo "$dir"/{module,system}.prop
# Copy relevant files
cp "$dir"/{module,system}.prop "result/$base_name/"
cp -r ./magisk_module_files/* "result/$base_name/"

# Archive the module as zip
cd "result/$base_name" || exit 1
zip -r -q "../../$base_name".zip .
cd ../..

module_hash=$(sha256sum "$base_name.zip" | awk '{print $1}')
print_message "Module saved to \"$base_name.zip\" ($module_hash)\n" debug

# Save build information for GitHub output
if [[ -n "$GITHUB_OUTPUT" ]]; then
	{
		echo "module_base_name=$base_name"
		echo "module_hash=$module_hash"
		echo "device_name=$device_name"
		echo "device_codename=$device_codename"
		echo "device_build_id=$device_build_id"
		echo "device_build_description=$device_build_description"
		echo "device_build_android_version=$device_build_android_version"
		echo "device_build_security_patch=$device_build_security_patch"
	} >>"$GITHUB_OUTPUT"
fi
