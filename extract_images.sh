#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Extracted image paths
EI="./extracted_images"
EAI="./extracted_archive_images"
EI_BP="${EI##"./"}"
EAI_BP="${EAI##"./"}"

# Extract payload as ota or system image if factory
[ -d "dl" ] && print_message "Extracting images from the Android OTA update package or factory image…\n" info
for file in ./dl/*; do                                      # Iterate through files in the directory ./dl/*
	if [ -f "${file:?}" ] && [ "${file: -4}" == ".zip" ]; then # Check if it is a ZIP file
		filename="${file##*/}"                                    # Extract the filename (remove the path)
		basename="${filename%.*}"                                 # Extract the basename (remove the extension)
		# devicename="${basename%%-*}"                              # Extract the device name (remove the extension)
		print_message "Processing \"$filename\"…" info

		# Time the extraction
		extraction_start=$(date +%s)

		# Extract images
		if unzip -l "$file" | grep -q "payload.bin"; then
			print_message "Extracting OTA image…" debug

			# Skip image if it failed to get extracted
			if ! 7z e "$file" -o"$EAI" "payload.bin" -r &>/dev/null; then
				print_message "Failed to extract payload.bin from $file using 7z. Skipping…\n" warning
				continue
			fi

			# If it managed to dump the payload then move it correspondingly.
			mv -f "$EAI_BP/payload.bin" "$EAI/$basename.bin"
			print_message "Saved to \"$EAI/$basename.bin\"." debug
		else
			print_message "Detected Factory image, Extracting everything…" debug

			# Skip image if it failed to get extracted
			if ! 7z e "$file" -o"$EAI_BP" -r -y &>/dev/null; then
				print_message "Failed to extract everything from $file. Skipping…" warning
				continue
			fi
		fi

		# We dont need the downloaded archive image anymore
		rm "$file"

		# Time the extraction
		extraction_end=$(date +%s)
		extraction_runtime=$((extraction_end - extraction_start))

		# Print the time
		print_message "Extraction time: $extraction_runtime seconds\n" debug
	fi
done

if [ -d "$EAI_BP" ]; then
	if [ -n "$(ls -A "$EAI_BP"/*.{zip,bin} 2>/dev/null)" ]; then
		print_message "Dumping images from \"$EAI_BP\"…\n" info

		for file in "$EAI"/*.{zip,bin}; do                                         # List directory zip & bin files
			if [ -f "${file:?}" ] && [[ "$file" == *.zip || "$file" == *.bin ]]; then # Check if file is a zip or bin file
				filename="${file##*/}"                                                   # Remove the path
				basename="${filename%.*}"                                                # Remove the extension
				print_message "Processing \"$filename\"…" info

				# Time the extraction
				extraction_start=$(date +%s)

				# Extract/Dump
				if [ "${file: -4}" == ".bin" ]; then # If is payload use the Android OTA Dumper
					# Format the patitions to dump for argument usage
					partitionsArgs=$(
						IFS=,
						echo "${PARTITIONS2EXTRACT[*]}"
					)

					# Skip image if it failed to get extracted
					if ! payload_dumper "$file" --partitions="$partitionsArgs" --out="$EI_BP/$basename" 2>/dev/null; then
						print_message "Failed to extract $file using Android OTA Dumper. Skipping…\n" warning
						rm -rf "$EI_BP/$basename" # TODO: Use "${var:?}" to ensure this never expands to / .
						continue
					fi
				else # Else directly extract all the required image using 7z
					for image_name in "${PARTITIONS2EXTRACT[@]}"; do
						print_message "Extracting \"$image_name\"…" debug

						# Skip image if it failed to get extracted
						if ! 7z e "$file" -o"$EI_BP/$basename" "$image_name.img" -r &>/dev/null; then
							print_message "Failed to extract $image_name.img from $file using 7z. Skipping…\n" warning
							rm -rf "$EI_BP/$basename/$image_name.img"
							continue
						fi
					done
				fi

				# We dont need the image anymore
				rm "$file"

				# Time the extraction
				extraction_end=$(date +%s)
				extraction_runtime=$((extraction_end - extraction_start))

				# Print the time
				print_message "Extraction time: $extraction_runtime seconds\n" debug
			fi
		done
	else
		print_message "The directory \"$EAI_BP\" does not have any ZIP or BIN files.\n" error
	fi
fi

# Extract the images directories
[ -d "$EI" ] && print_message "Extracting images…\n" info
for dir in "$EI"/*; do  # List directory ./*
	if [ -d "$dir" ]; then # Check if it is a directory
		dir=${dir%*/}         # Remove last /
		print_message "Processing \"${dir##*/}\"…" info

		# Time the extraction
		extraction_start=$(date +%s)

		# Extract all and clean
		for image_name in "${PARTITIONS2EXTRACT[@]}"; do
			if [ -f "$dir/$image_name.img" ]; then
				extract_image "$dir" "$image_name"
				rm "$dir/$image_name.img"
			fi
		done

		# Time the extraction
		extraction_end=$(date +%s)
		extraction_runtime=$((extraction_end - extraction_start))

		# Print the extraction time
		print_message "Extraction time: $extraction_runtime seconds\n" debug
	fi
done

# Build props, feature and module files after extraction
[ -d "$EI" ] && print_message "Building module props and features…\n" info
for dir in "$EI"/*; do  # List directory ./*
	if [ -d "$dir" ]; then # Check if it is a directory
		dir=${dir%*/}         # Remove last /
		print_message "Processing \"${dir##*/}\"…" info

		# Time the extraction
		extraction_start=$(date +%s)

		# Build system.prop
		print_message "Building props…" info
		./build_props.sh "$dir"

		# Build product sysconfig for Pixel Experience features
		print_message "Building sysconfig features…" info
		./build_sysconfig.sh "$dir"

		# Build media bootanimation
		# (Optional) It increases the module size significantly!
		# print_message "Building media bootanimation…" info
		# ./build_bootanimation.sh "$dir"

		# Build Magisk module
		print_message "Building module…" info
		./build_module.sh "$dir"

		# Time the extraction
		extraction_end=$(date +%s)
		extraction_runtime=$((extraction_end - extraction_start))

		# Print the build time
		print_message "Build time: $extraction_runtime seconds\n" debug
	fi
done
