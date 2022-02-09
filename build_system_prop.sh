# Using util_functions.sh
[ -f "util_functions.sh" ] && . ./util_functions.sh || { echo "util_functions.sh not found" && exit 1; }

# Display usage
[ ! -z $1 ] && dir=$1 || {
	print_message "Usage: $0 <directory>" error
	exit 1
}

# Building props config from there
system_prop=""

# Define the props path
product_path="$dir/extracted/product/etc/build.prop"
vendor_path="$dir/extracted/vendor/build.prop"
vendor_odm_path="$dir/extracted/vendor/odm/etc/build.prop"
system_path="$dir/extracted/system/system/build.prop"
system_ext_path="$dir/extracted/system_ext/etc/build.prop"

# Build our system.prop
add_system_prop "##
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
build_prop "$product_path" "ro.product.product.brand"
build_prop "$product_path" "ro.product.product.device"
build_prop "$product_path" "ro.product.product.manufacturer"
build_prop "$product_path" "ro.product.product.model"
build_prop "$product_path" "ro.product.product.name"
build_prop "$product_path" "ro.product.build.date"
build_prop "$product_path" "ro.product.build.date.utc"
build_prop "$product_path" "ro.product.build.fingerprint"
build_prop "$product_path" "ro.product.build.id"
build_prop "$product_path" "ro.product.build.tags"
build_prop "$product_path" "ro.product.build.type"
build_prop "$product_path" "ro.product.build.version.incremental"
build_prop "$product_path" "ro.product.build.version.release"
build_prop "$product_path" "ro.product.build.version.release_or_codename"
build_prop "$product_path" "ro.product.build.version.sdk"
add_system_prop "# end common build properties

# begin PRODUCT_PRODUCT_PROPERTIES
ro.support_one_handed_mode=true
ro.charger.enable_suspend=true
ro.opa.eligible_device=true
ro.com.google.ime.bs_theme=true
ro.com.google.ime.theme_id=5
ro.com.google.ime.system_lm_dir=/product/usr/share/ime/google/d3_lms
# end PRODUCT_PRODUCT_PROPERTIES

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
build_prop "$vendor_path" "ro.product.vendor.brand"
build_prop "$vendor_path" "ro.product.vendor.device"
build_prop "$vendor_path" "ro.product.vendor.manufacturer"
build_prop "$vendor_path" "ro.product.vendor.model"
build_prop "$vendor_path" "ro.product.vendor.name"
build_prop "$vendor_path" "ro.vendor.build.date"
build_prop "$vendor_path" "ro.vendor.build.date.utc"
build_prop "$vendor_path" "ro.vendor.build.fingerprint"
build_prop "$vendor_path" "ro.vendor.build.id"
build_prop "$vendor_path" "ro.vendor.build.tags"
build_prop "$vendor_path" "ro.vendor.build.type"
build_prop "$vendor_path" "ro.vendor.build.version.incremental"
build_prop "$vendor_path" "ro.vendor.build.version.release"
build_prop "$vendor_path" "ro.vendor.build.version.release_or_codename"
build_prop "$vendor_path" "ro.vendor.build.version.sdk"
add_system_prop "# end common build properties

# begin ADDITIONAL_VENDOR_PROPERTIES"
build_prop "$vendor_path" "ro.vendor.build.security_patch"
add_system_prop "# end ADDITIONAL_VENDOR_PROPERTIES

# begin BOOTIMAGE_BUILD_PROPERTIES"
add_prop_system_prop "ro.bootimage.build.date" "$(grep_prop "ro.vendor.build.date" $vendor_path)"
add_prop_system_prop "ro.bootimage.build.date.utc" "$(grep_prop "ro.vendor.build.date.utc" $vendor_path)"
add_prop_system_prop "ro.bootimage.build.fingerprint" "$(grep_prop "ro.vendor.build.fingerprint" $vendor_path)"
add_system_prop "# end BOOTIMAGE_BUILD_PROPERTIES

# begin PRODUCT_PROPERTY_OVERRIDES
persist.rcs.supported=1
persist.sysui.monet=true
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
build_prop "$vendor_odm_path" "ro.product.odm.brand"
build_prop "$vendor_odm_path" "ro.product.odm.device"
build_prop "$vendor_odm_path" "ro.product.odm.manufacturer"
build_prop "$vendor_odm_path" "ro.product.odm.model"
build_prop "$vendor_odm_path" "ro.product.odm.name"
build_prop "$vendor_odm_path" "ro.odm.build.date"
build_prop "$vendor_odm_path" "ro.odm.build.date.utc"
build_prop "$vendor_odm_path" "ro.odm.build.fingerprint"
build_prop "$vendor_odm_path" "ro.odm.build.id"
build_prop "$vendor_odm_path" "ro.odm.build.tags"
build_prop "$vendor_odm_path" "ro.odm.build.type"
build_prop "$vendor_odm_path" "ro.odm.build.version.incremental"
build_prop "$vendor_odm_path" "ro.odm.build.version.release"
build_prop "$vendor_odm_path" "ro.odm.build.version.release_or_codename"
build_prop "$vendor_odm_path" "ro.odm.build.version.sdk"
add_system_prop "# end common build properties

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
build_prop "$system_path" "ro.product.system.brand"
build_prop "$system_path" "ro.product.system.device"
build_prop "$system_path" "ro.product.system.manufacturer"
build_prop "$system_path" "ro.product.system.model"
build_prop "$system_path" "ro.product.system.name"
build_prop "$system_path" "ro.system.build.date"
build_prop "$system_path" "ro.system.build.date.utc"
build_prop "$system_path" "ro.system.build.fingerprint"
build_prop "$system_path" "ro.system.build.id"
build_prop "$system_path" "ro.system.build.tags"
build_prop "$system_path" "ro.system.build.type"
build_prop "$system_path" "ro.system.build.version.incremental"
build_prop "$system_path" "ro.system.build.version.release"
build_prop "$system_path" "ro.system.build.version.release_or_codename"
build_prop "$system_path" "ro.system.build.version.sdk"
add_system_prop "# end common build properties

# begin build properties"
build_prop "$system_path" "ro.build.id"
build_prop "$system_path" "ro.build.display.id"
build_prop "$system_path" "ro.build.version.incremental"
build_prop "$system_path" "ro.build.version.sdk"
build_prop "$system_path" "ro.build.version.release"
build_prop "$system_path" "ro.build.version.release_or_codename"
build_prop "$system_path" "ro.build.version.security_patch"
build_prop "$system_path" "ro.build.date"
build_prop "$system_path" "ro.build.date.utc"
build_prop "$system_path" "ro.build.type"
build_prop "$system_path" "ro.build.user"
build_prop "$system_path" "ro.build.host"
build_prop "$system_path" "ro.build.tags"
build_prop "$system_path" "ro.build.flavor"
build_prop "$system_path" "ro.build.product"
build_prop "$system_path" "ro.build.description"
add_system_prop "# end build properties

# begin extra's from /system/build.prop"
add_prop_system_prop "ro.build.fingerprint" "$(grep_prop "ro.system.build.fingerprint" $system_path)"
add_prop_system_prop "ro.product.brand" "$(grep_prop "ro.product.system.brand" $system_path)"
add_prop_system_prop "ro.product.device" "$(grep_prop "ro.build.product" $system_path)"
add_prop_system_prop "ro.product.manufacturer" "$(grep_prop "ro.product.system.manufacturer" $system_path)"
add_prop_system_prop "ro.product.model" "$(grep_prop "ro.product.vendor.model" $vendor_path)"
add_prop_system_prop "ro.product.name" "$(grep_prop "ro.build.product" $system_path)"
add_system_prop "# end extra's from /system/build.prop

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
build_prop "$system_ext_path" "ro.product.system_ext.brand"
build_prop "$system_ext_path" "ro.product.system_ext.device"
build_prop "$system_ext_path" "ro.product.system_ext.manufacturer"
build_prop "$system_ext_path" "ro.product.system_ext.model"
build_prop "$system_ext_path" "ro.product.system_ext.name"
build_prop "$system_ext_path" "ro.system_ext.build.date"
build_prop "$system_ext_path" "ro.system_ext.build.date.utc"
build_prop "$system_ext_path" "ro.system_ext.build.fingerprint"
build_prop "$system_ext_path" "ro.system_ext.build.id"
build_prop "$system_ext_path" "ro.system_ext.build.tags"
build_prop "$system_ext_path" "ro.system_ext.build.type"
build_prop "$system_ext_path" "ro.system_ext.build.version.incremental"
build_prop "$system_ext_path" "ro.system_ext.build.version.release"
build_prop "$system_ext_path" "ro.system_ext.build.version.release_or_codename"
build_prop "$system_ext_path" "ro.system_ext.build.version.sdk"
add_system_prop "# end common build properties

###
# end system_ext/etc/build.prop
###"

# Save the system.prop file
echo -n "${system_prop::-1}" >"$dir/extracted/system.prop"

# Display saving location
print_message "Saved to \"$dir/extracted/system.prop\"" info
