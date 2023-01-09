#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Extract payload as ota or system image if factory
print_message "Extracting images from archives..." info
for file in ./*; do                    # List directory ./*
	if [ -f "$file" ]; then               # Check if it is a file
		if [ "${file: -4}" == ".zip" ]; then # Check if it is a zip file
			filename="${file##*/}"              # Remove the path
			basename="${filename%.*}"           # Remove the extension
			devicename="${basename%%-*}"        # Remove the extension
			print_message "Processing \"$filename\"" debug

			# Time the extraction
			extraction_start=$(date +%s)

			# Extract images
			if [[ ! "${basename##"$devicename"-ota-*}" ]]; then # Presume if the image is OTA or Factory based on devicename
				7z e "$file" -o"extracted_archive_images" "payload.bin" -r &>/dev/null
				mv -f "extracted_archive_images/payload.bin" "extracted_archive_images/$basename.bin"
			else # else assume it is factory and extract everything
				7z e "$file" -o"extracted_archive_images" "*/*.zip" -r -y &>/dev/null
			fi

			# We dont need the archive anymore
			rm "$file"

			# Time the extraction
			extraction_end=$(date +%s)
			extraction_runtime=$((extraction_end - extraction_start))

			# Print the time
			print_message "Extraction time: $extraction_runtime seconds" debug
		fi
	fi
done

if [ -d "extracted_archive_images" ]; then
	print_message "\nExtracting/Dumping images from \"extracted_archive_images\"..." info

	for file in ./extracted_archive_images/*; do                          # List directory ./extracted_archive_images/*
		if [ -f "$file" ]; then                                              # Check if it is a file
			if [ "${file: -4}" == ".zip" ] || [ "${file: -4}" == ".bin" ]; then # Check if it is a zip or bin file
				filename="${file##*/}"                                             # Remove the path
				basename="${filename%.*}"                                          # Remove the extension
				print_message "Processing \"$filename\"" debug

				# Time the extraction
				extraction_start=$(date +%s)

				# Extract/Dump
				if [ "${file: -4}" == ".bin" ]; then # If is payload use the Android OTA Dumper
					python3 ota_dumper/extract_android_ota_payload.py "$file" "extracted_images/$basename"
				else # else directly extract the required images
					for image_name in "${IMAGES2EXTRACT[@]}"; do
						print_message "Extracting \"$image_name\"..." debug
						7z e "$file" -o"extracted_images/$basename" "$image_name.img" -r &>/dev/null
					done
				fi

				# Time the extraction
				extraction_end=$(date +%s)
				extraction_runtime=$((extraction_end - extraction_start))

				# Print the time
				print_message "Extraction time: $extraction_runtime seconds" debug
			fi
		fi
	done

	rm -rf "extracted_archive_images"
fi

# Extract the images directories
print_message "\nExtracting images and directories..." info
for dir in ./extracted_images/*; do # List directory ./*
	if [ -d "$dir" ]; then             # Check if it is a directory
		dir=${dir%*/}                     # Remove last /
		print_message "Processing \"${dir##*/}\"" debug

		# Time the extraction
		extraction_start=$(date +%s)

		# Extract all and clean
		for image_name in "${IMAGES2EXTRACT[@]}"; do
			extract_image "$dir" "$image_name"
			rm "$dir/$image_name.img"
		done

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
