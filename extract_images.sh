#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Extract the factory images
print_message "Extracting factory images..." info
for file in ./*; do                    # List directory ./*
	if [ -f "$file" ]; then               # Check if it is a file
		if [ "${file: -4}" == ".zip" ]; then # Check if it is a zip file
			print_message "Processing \"${file##*/}\"" debug

			# Time the extraction
			extraction_start=$(date +%s)

			# Extract images
			7z e "$file" -o"extracted_factoryimages" "*/*.zip" -r -y &>/dev/null
			rm "$file"

			# Time the extraction
			extraction_end=$(date +%s)
			extraction_runtime=$((extraction_end - extraction_start))

			# Print the time
			print_message "Extraction time: $extraction_runtime seconds" debug
		fi
	fi
done

if [ -d "extracted_factoryimages" ]; then
	print_message "\nExtracting images from \"extracted_factoryimages\"..." info

	for file in ./extracted_factoryimages/*; do # List directory ./extracted_factoryimages/*
		if [ -f "$file" ]; then                    # Check if it is a file
			if [ "${file: -4}" == ".zip" ]; then      # Check if it is a zip file
				filename="${file##*/}"                   # Remove the path
				basename="${filename%.*}"                # Remove the extension
				print_message "Processing \"$filename\"" debug

				# Time the extraction
				extraction_start=$(date +%s)

				# Extract images
				7z x "$file" -o"$basename" -y &>/dev/null

				# Time the extraction
				extraction_end=$(date +%s)
				extraction_runtime=$((extraction_end - extraction_start))

				# Print the time
				print_message "Extraction time: $extraction_runtime seconds" debug
			fi
		fi
	done

	rm -rf "extracted_factoryimages"
fi

# Extract the images directories
print_message "\nExtracting images directories..." info
for dir in ./*; do      # List directory ./*
	if [ -d "$dir" ]; then # Check if it is a directory
		dir=${dir%*/}         # Remove last /
		print_message "Processing \"${dir##*/}\"" debug

		# Time the extraction
		extraction_start=$(date +%s)

		# Extracting each image
		extract_image "$dir" "product"
		extract_image "$dir" "vendor"
		extract_image "$dir" "system"
		extract_image "$dir" "system_ext"

		# Time the extraction
		extraction_end=$(date +%s)
		extraction_runtime=$((extraction_end - extraction_start))

		# Print the extraction time
		print_message "Extraction time: $extraction_runtime seconds" debug

		# Build system.prop
		print_message "Building props..." info
		./build_props.sh "$dir"
	fi
done
