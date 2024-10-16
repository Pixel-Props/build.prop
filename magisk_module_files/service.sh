#!/system/bin/sh

MODPATH="${0%/*}"
MODPATH_SYSTEM_PROP=$([ -d "$MODPATH_SYSTEM_PROP" ] || echo "$MODPATH/system.prop")

# Define the props path
MODPROP_FILES=$(find_prop_files "$MODPATH/" 1)
SYSPROP_FILES=$(find_prop_files "/" 3)

# Store the content of all prop files in a variable
MODPROP_CONTENT=$(echo "$MODPROP_FILES" | xargs cat)
SYSPROP_CONTENT=$(echo "$SYSPROP_FILES" | xargs cat)

# Function to check and update a property
check_and_update_prop() {
  sys_prop_key="$1"
  mod_prop_key="$2"
  prop_name="$3"
  comparison="$4"

  sys_prop=$(grep_prop "$sys_prop_key" "$SYSPROP_CONTENT")
  mod_prop=$(grep_prop "$mod_prop_key" "$MODPROP_CONTENT")

  case "$comparison" in
  "eq") [ "$sys_prop" -eq "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$mod_prop_key" || ignore_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "ne") [ "$sys_prop" -ne "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$mod_prop_key" || ignore_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "lt") [ "$sys_prop" -lt "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$mod_prop_key" || ignore_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "le") [ "$sys_prop" -le "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$mod_prop_key" || ignore_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "gt") [ "$sys_prop" -gt "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$mod_prop_key" || ignore_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "ge") [ "$sys_prop" -ge "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$mod_prop_key" || ignore_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  esac
}

update_prop() {
  ui_print " - $1=$2, unsafe property…"
  sed -i "s/^# $3/$3/" "$MODPATH_SYSTEM_PROP"
}

ignore_prop() {
  ui_print " - $1=$2, safe property."
  sed -i "s/^$3/# $3/" "$MODPATH_SYSTEM_PROP"
}

# Check and update properties
ui_print ""
check_and_update_prop "ro.product.device" "ro.product.device" "PRODUCT_DEVICE" "ne"
check_and_update_prop "ro.product.vendor.device" "ro.product.vendor.device" "VENDOR_DEVICE" "ne"
check_and_update_prop "ro.product.build.version.sdk" "ro.product.build.version.sdk" "SDK" "lt"
check_and_update_prop "ro.product.build.version.release" "ro.product.build.version.release" "BUILD_VERSION" "lt"
check_and_update_prop "ro.product.build.version.release_or_codename" "ro.product.build.version.release_or_codename" "BUILD_VERSION_CODENAME" "lt"

ui_print "  ? When a property was detected as unsafe, It will be removed from the spoof."
ui_print ""
