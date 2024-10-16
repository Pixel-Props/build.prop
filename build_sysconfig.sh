#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Function 
copy_specific_files() {
	local directory="$1/extracted/product/etc/sysconfig"
	local dest_directory="$1/sysconfig/"

	# Create the destination directory if it doesn't exist
	mkdir -p "$dest_directory"

	# Define the files to copy
	local files_to_copy=(
		"pixel_experience_"
		"nga"
		"google.xml"
		"google_build.xml"
		"google_fi.xml"
		"adaptivecharging.xml"
		"quick_tap.xml"
	)

	# Loop through each file in the directory
	for file in "$directory"/*; do
		# Get the file name
		local file_name="${file##*/}"

		# Check if the file name matches any of the files to copy
		for copy_file in "${files_to_copy[@]}"; do
			if [[ "$file_name" == *"$copy_file"* ]]; then
				# Copy the file to the destination directory
				cp "$file" "$dest_directory"
				break
			fi
		done
	done
}

# Build props from script base path if no directory were specified
[ -n "$1" ] && dir=$1 || {
	for dir in ./extracted_images/*; do # List directory ./*
		if [ -d "$dir" ]; then             # Check if it is a directory
			dir=${dir%*/}                     # Remove last /
			print_message "Processing \"${dir##*/}\"" debug

			# Execute current script using first argument as dir
			./"${BASH_SOURCE[0]}" "$dir"
		fi
	done
	exit 1
}

copy_specific_files "$dir"
