#!/bin/bash

# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Build props from script base path if no directory were specified
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

# Define the props path
declare EXT_PROP_FILES=$(find_prop_files "$dir")

# Store the content of all prop files in a variable
declare EXT_PROP_CONTENT=$(cat $EXT_PROP_FILES)

# Building props config from there
system_prop=""
module_prop=""

###
# System Props
###

# Build our system.prop
to_system_prop "##
# Beautiful Pixel Props https://t.me/PixelProps
# By @T3SL4
##

###
#-#
###

###
# begin product/etc/build.prop
###

# begin common build properties"
add_prop_as_ini to_system_prop "ro.product.brand" "$(grep_prop "ro.product.vendor.brand" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.device" "$(grep_prop "ro.product.vendor.device" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.manufacturer" "$(grep_prop "ro.product.vendor.manufacturer" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.model" "$(grep_prop "ro.product.vendor.model" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.name" "$(grep_prop "ro.product.vendor.name" "$EXT_PROP_CONTENT")"
build_system_prop "ro.product.product.brand"
build_system_prop "ro.product.product.device"
build_system_prop "ro.product.product.manufacturer"
build_system_prop "ro.product.product.model"
build_system_prop "ro.product.product.name"
build_system_prop "ro.product.name_for_attestation"
build_system_prop "ro.product.build.date"
build_system_prop "ro.product.build.date.utc"
build_system_prop "ro.product.build.fingerprint"
build_system_prop "ro.product.build.id"
build_system_prop "ro.product.build.tags"
build_system_prop "ro.product.build.type"
build_system_prop "ro.product.build.version.incremental"
build_system_prop "ro.product.build.version.release"
build_system_prop "ro.product.build.version.release_or_codename"
build_system_prop "ro.product.build.version.sdk"
to_system_prop "# end common build properties

# begin PRODUCT_PRODUCT_PROPERTIES"
build_system_prop "ro.support_one_handed_mode"
build_system_prop "ro.opa.eligible_device"
build_system_prop "ro.com.google.ime.theme_id"
build_system_prop "ro.com.google.ime.system_lm_dir"
to_system_prop "# end PRODUCT_PRODUCT_PROPERTIES

# begin PRODUCT_BOOTIMAGE_PROPERTIES"
add_prop_as_ini to_system_prop "ro.product.bootimage.brand" "$(grep_prop "ro.product.vendor.brand" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.bootimage.device" "$(grep_prop "ro.product.vendor.device" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.bootimage.manufacturer" "$(grep_prop "ro.product.vendor.manufacturer" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.bootimage.model" "$(grep_prop "ro.product.vendor.model" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.product.bootimage.name" "$(grep_prop "ro.product.vendor.name" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.date" "$(grep_prop "ro.vendor.build.date" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.date.utc" "$(grep_prop "ro.vendor.build.date.utc" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.fingerprint" "$(grep_prop "ro.vendor.build.fingerprint" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.id" "$(grep_prop "ro.vendor.build.id" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.tags" "$(grep_prop "ro.vendor.build.tags" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.type" "$(grep_prop "ro.vendor.build.type" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.version.incremental" "$(grep_prop "ro.vendor.build.version.incremental" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.version.release" "$(grep_prop "ro.vendor.build.version.release" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.version.release_or_codename" "$(grep_prop "ro.vendor.build.version.release_or_codename" "$EXT_PROP_CONTENT")"
add_prop_as_ini to_system_prop "ro.bootimage.build.version.sdk" "$(grep_prop "ro.vendor.build.version.sdk" "$EXT_PROP_CONTENT")"
to_system_prop "# end PRODUCT_BOOTIMAGE_PROPERTIES

###
# end product/etc/build.prop
###

###
#-#
###

###
# begin vendor/build.prop
###

# begin common build properties"
build_system_prop "ro.product.vendor.brand"
build_system_prop "ro.product.vendor.device"
build_system_prop "ro.product.vendor.manufacturer"
build_system_prop "ro.product.vendor.model"
build_system_prop "ro.product.vendor.name"
build_system_prop "ro.vendor.build.date"
build_system_prop "ro.vendor.build.date.utc"
build_system_prop "ro.vendor.build.fingerprint"
build_system_prop "ro.vendor.build.id"
build_system_prop "ro.vendor.build.tags"
build_system_prop "ro.vendor.build.type"
build_system_prop "ro.vendor.build.version.incremental"
build_system_prop "ro.vendor.build.version.release"
build_system_prop "ro.vendor.build.version.release_or_codename"
build_system_prop "ro.vendor.build.version.sdk"
to_system_prop "# end common build properties

# begin PRODUCT_VENDOR_PROPERTIES"
# add_prop_as_ini to_system_prop "ro.hardware" "$(grep_prop "ro.product.vendor.device" "$EXT_PROP_CONTENT")"
# build_system_prop "ro.hardware.egl"
# build_system_prop "ro.hardware.vulkan"
build_system_prop "ro.soc.model"
build_system_prop "ro.soc.manufacturer"
to_system_prop "# end PRODUCT_VENDOR_PROPERTIES

# begin ADDITIONAL_VENDOR_PROPERTIES"
# build_system_prop "ro.product.board"
build_system_prop "ro.product.first_api_level"
build_system_prop "ro.vendor.build.security_patch"
# build_system_prop "ro.board.platform"
to_system_prop "# end ADDITIONAL_VENDOR_PROPERTIES

# begin PRODUCT_PROPERTY_OVERRIDES
debug.sf.enable_sdr_dimming=1
debug.sf.dim_in_gamma_in_enhanced_screenshots=1
persist.vendor.enable.thermal.genl=true
suspend.short_suspend_threshold_millis=2000
suspend.max_sleep_time_millis=40000
suspend.short_suspend_backoff_enabled=true
ro.incremental.enable=true
# end PRODUCT_PROPERTY_OVERRIDES

###
# end vendor/build.prop
###

###
#-#
###

###
# begin vendor/odm/etc/build.prop
###

# begin common build properties"
build_system_prop "ro.product.odm.brand"
build_system_prop "ro.product.odm.device"
build_system_prop "ro.product.odm.manufacturer"
build_system_prop "ro.product.odm.model"
build_system_prop "ro.product.odm.name"
build_system_prop "ro.odm.build.date"
build_system_prop "ro.odm.build.date.utc"
build_system_prop "ro.odm.build.fingerprint"
build_system_prop "ro.odm.build.id"
build_system_prop "ro.odm.build.tags"
build_system_prop "ro.odm.build.type"
build_system_prop "ro.odm.build.version.incremental"
build_system_prop "ro.odm.build.version.release"
build_system_prop "ro.odm.build.version.release_or_codename"
build_system_prop "ro.odm.build.version.sdk"
to_system_prop "# end common build properties

###
# end vendor/odm/etc/build.prop
###

###
#-#
###

###
# begin system/system/build.prop
###

# begin common build properties"
build_system_prop "ro.product.system.brand"
build_system_prop "ro.product.system.device"
build_system_prop "ro.product.system.manufacturer"
build_system_prop "ro.product.system.model"
build_system_prop "ro.product.system.name"
build_system_prop "ro.system.build.date"
build_system_prop "ro.system.build.date.utc"
build_system_prop "ro.system.build.fingerprint"
build_system_prop "ro.system.build.id"
build_system_prop "ro.system.build.tags"
build_system_prop "ro.system.build.type"
build_system_prop "ro.system.build.version.incremental"
build_system_prop "ro.system.build.version.release"
build_system_prop "ro.system.build.version.release_or_codename"
build_system_prop "ro.system.build.version.sdk"
to_system_prop "# end common build properties

# begin build properties"
build_system_prop "ro.build.date"
build_system_prop "ro.build.date.utc"
add_prop_as_ini to_system_prop "ro.build.fingerprint" "$(grep_prop "ro.system.build.fingerprint" "$EXT_PROP_CONTENT")"
build_system_prop "ro.build.id"
build_system_prop "ro.build.display.id"
build_system_prop "ro.build.type"
build_system_prop "ro.build.user"
build_system_prop "ro.build.host"
build_system_prop "ro.build.tags"
build_system_prop "ro.build.flavor"
build_system_prop "ro.build.product"
build_system_prop "ro.build.description"
build_system_prop "ro.build.version.incremental"
build_system_prop "ro.build.version.sdk"
build_system_prop "ro.build.version.release"
build_system_prop "ro.build.version.release_or_codename"
build_system_prop "ro.build.version.security_patch"
to_system_prop "# end build properties

# begin PRODUCT_SYSTEM_PROPERTIES"
build_system_prop "ro.hotword.detection_service_required"
to_system_prop "#end PRODUCT_SYSTEM_PROPERTIES

###
# end system/system/build.prop
###

###
#-#
###

###
# begin system_ext/etc/build.prop
###

# begin common build properties"
build_system_prop "ro.product.system_ext.brand"
build_system_prop "ro.product.system_ext.device"
build_system_prop "ro.product.system_ext.manufacturer"
build_system_prop "ro.product.system_ext.model"
build_system_prop "ro.product.system_ext.name"
build_system_prop "ro.system_ext.build.date"
build_system_prop "ro.system_ext.build.date.utc"
build_system_prop "ro.system_ext.build.fingerprint"
build_system_prop "ro.system_ext.build.id"
build_system_prop "ro.system_ext.build.tags"
build_system_prop "ro.system_ext.build.type"
build_system_prop "ro.system_ext.build.version.incremental"
build_system_prop "ro.system_ext.build.version.release"
build_system_prop "ro.system_ext.build.version.release_or_codename"
build_system_prop "ro.system_ext.build.version.sdk"
to_system_prop "# end common build properties

###
# end system_ext/etc/build.prop
###"

# Save the system.prop file
echo -n "${system_prop::-1}" >"$dir/system.prop"

###
# Module Props
###
device_name=$(grep_prop "ro.product.vendor.model" "$EXT_PROP_CONTENT")
device_build_description=$(grep_prop "ro.build.description" "$EXT_PROP_CONTENT")
device_code_name=$(grep_prop "ro.product.vendor.name" "$EXT_PROP_CONTENT")
device_build_security_patch=$(grep_prop "ro.vendor.build.security_patch" "$EXT_PROP_CONTENT")
device_build_fingerprint=$(grep_prop "ro.product.build.id" "$EXT_PROP_CONTENT")

add_prop_as_ini to_module_prop "id" "${device_code_name^}_Prop"
add_prop_as_ini to_module_prop "name" "$device_name (${device_code_name^^}) Prop"
add_prop_as_ini to_module_prop "version" "$device_build_security_patch"
add_prop_as_ini to_module_prop "versionCode" "$(echo "$device_build_security_patch" | tr -d - | cut -c3-)"
add_prop_as_ini to_module_prop "author" "Tesla"
add_prop_as_ini to_module_prop "description" "Spoof your device props to ${device_code_name^^} [$device_build_fingerprint] ($(date --date="$device_build_security_patch" +%b) $(date --date="$device_build_security_patch" +%Y))"
add_prop_as_ini to_module_prop "donate" "https://wannabe1337.page.link/4xK6"
add_prop_as_ini to_module_prop "support" "https://t.me/PixelProps"

# Save the module.prop file
echo -n "${module_prop::-1}" >"$dir/module.prop"

# Display information about prop
print_message "Built props for $device_name [$device_build_description]!" info

# Display saving location
print_message "Props saved to \"${dir}\"" debug

# Build Magisk module
print_message "Building module…" info
./build_magisk_module.sh "$dir"
