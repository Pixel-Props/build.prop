#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Start processing directories (default to ./extracted_images)
process_directories "${BASH_SOURCE[0]}" "$1"

# Current basename
base_name=$(basename "$dir")

# Define the props path
declare EXT_PROP_FILES=$(find_prop_files "$dir")

# Store the content of all prop files in a variable
declare EXT_PROP_CONTENT=$(cat $EXT_PROP_FILES)

# Save module device information
device_name=$(grep_prop "ro.product.model" "$EXT_PROP_CONTENT")
device_build_id=$(grep_prop "ro.build.id" "$EXT_PROP_CONTENT")
device_codename=$(grep_prop "ro.product.vendor.name" "$EXT_PROP_CONTENT")
device_build_description=$(grep_prop "ro.build.description" "$EXT_PROP_CONTENT")
device_build_android_version=$(grep_prop "ro.vendor.build.version.release" "$EXT_PROP_CONTENT")
device_build_security_patch=$(grep_prop "ro.vendor.build.security_patch" "$EXT_PROP_CONTENT")
device_codename=${device_codename^}

# Construct the result base
base_name="${device_codename}_$device_build_id"
mkdir -p "result/$base_name/"
mkdir -p "result/$base_name/system/product/etc/"

# Copy relevant files
cp "$dir"/{module,system}.prop "result/$base_name/"
cp -r "$dir"/system/ "result/$base_name/"
cp -r ./module_files/* "result/$base_name/"

# Navigate to the module directory
cd "result/$base_name" || exit 1

# Enumerate and hash all the scripts inside the module
find . -type f \( -name "*.sh" -o -name "update-binary" -o -name "updater-script" \) -print0 | while IFS= read -r -d '' file; do
	[ -f "$file" ] && sha256sum "$file" | awk '{print $1}' >"$file.sha256"
done

# Archive the module as zip
zip -r -q "../../$base_name".zip .

# Navigate out of the module directory
cd ../..

# Save the module hash
module_hash=$(sha256sum "$base_name.zip" | awk '{print $1}')
module_hash_upper=$(echo "$module_hash" | tr '[:lower:]' '[:upper:]')

# Display information about module
print_message "Built module ${base_name}.zip (SHA256: $module_hash_upper)" debug

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
