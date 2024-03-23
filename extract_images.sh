#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Extracted image paths
EI="./extracted_images"
EAI="./extracted_archive_images"
EI_BP="${EI##"./"}"
EAI_BP="${EAI##"./"}"

# Extract payload as ota or system image if factory
print_message "Extracting images from archives..." info
for file in ./dl/*; do                                  # Iterate through files in the directory ./dl/*
	if [ -f "$file" ] && [ "${file: -4}" == ".zip" ]; then # Check if it is a ZIP file
		filename="${file##*/}"                                # Extract the filename (remove the path)
		basename="${filename%.*}"                             # Extract the basename (remove the extension)
		# devicename="${basename%%-*}"                          # Extract the device name (remove the extension)
		print_message "Processing \"$filename\"..." info

		# Time the extraction
		extraction_start=$(date +%s)

		# Extract images
		if unzip -l "$file" | grep -q "payload.bin"; then # Presume if the image is OTA or Factory
			print_message "Extracting OTA image..." debug
			7z e "$file" -o"$EAI" "payload.bin" -r &>/dev/null
			mv -f "$EAI_BP/payload.bin" "$EAI/$basename.bin"
			print_message "Saved to \"$EAI/$basename.bin\"." debug
		else # else assume it is factory and extract everything
			print_message "Extracting all Factory image..." debug
			7z e "$file" -o"$EAI_BP" -r -y &>/dev/null
		fi

		# We dont need the archive anymore
		# rm "$file"

		# Time the extraction
		extraction_end=$(date +%s)
		extraction_runtime=$((extraction_end - extraction_start))

		# Print the time
		print_message "Extraction time: $extraction_runtime seconds" debug
	fi
done

if [ -d "$EAI_BP" ]; then
	if [ -n "$(ls -A "$EAI_BP"/*.{zip,bin} 2>/dev/null)" ]; then
		print_message "\nDumping images from \"$EAI_BP\"..." info

		for file in "$EAI"/*.{zip,bin}; do                                     # List directory zip & bin files
			if [ -f "$file" ] && [[ "$file" == *.zip || "$file" == *.bin ]]; then # Check if file is a zip or bin file
				filename="${file##*/}"                                               # Remove the path
				basename="${filename%.*}"                                            # Remove the extension
				print_message "Processing \"$filename\"..." info

				# Time the extraction
				extraction_start=$(date +%s)

				# Extract/Dump
				if [ "${file: -4}" == ".bin" ]; then # If is payload use the Android OTA Dumper
					python3 ota_dumper/extract_android_ota_payload.py "$file" "$EI_BP/$basename"
				else # else directly extract the required images
					for image_name in "${IMAGES2EXTRACT[@]}"; do
						print_message "Extracting \"$image_name\"..." debug
						7z e "$file" -o"$EI_BP/$basename" "$image_name.img" -r &>/dev/null
					done
				fi

				# We dont need the image anymore
				# rm "$file"

				# Time the extraction
				extraction_end=$(date +%s)
				extraction_runtime=$((extraction_end - extraction_start))

				# Print the time
				print_message "Extraction time: $extraction_runtime seconds" debug
			fi
		done
	else
		print_message "\nThe directory \"$EAI_BP\" does not have any ZIP or BIN files." error
	fi
fi

# Extract the images directories
print_message "\nExtracting images..." info
for dir in "$EI"/*; do  # List directory ./*
	if [ -d "$dir" ]; then # Check if it is a directory
		dir=${dir%*/}         # Remove last /
		print_message "Processing \"${dir##*/}\"..." info

		# Time the extraction
		extraction_start=$(date +%s)

		# Extract all and clean
		for image_name in "${IMAGES2EXTRACT[@]}"; do
			if [ -f "$dir/$image_name.img" ]; then
				extract_image "$dir" "$image_name"
				rm "$dir/$image_name.img"
			fi
		done

		# Time the extraction
		extraction_end=$(date +%s)
		extraction_runtime=$((extraction_end - extraction_start))

		# Print the extraction time
		print_message "Extraction time: $extraction_runtime seconds" debug

		# Build system.prop
		print_message "\nBuilding props..." info
		./build_props.sh "$dir"
	fi
done
