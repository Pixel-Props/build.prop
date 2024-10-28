#!/system/bin/busybox sh

MODPATH="${0%/*}"

# If MODPATH is empty or is not default modules path, use current path
if [ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/'; then
  MODPATH="$(dirname "$(readlink -f "$0")")"
fi

# Using util_functions.sh
[ -f "$MODPATH"/util_functions.sh ] && . "$MODPATH"/util_functions.sh || abort "! util_functions.sh not found!"

# Define the system.prop path and check if it exists and is writable
MODPATH_SYSTEM_PROP="$MODPATH/system.prop"
[ ! -f "$MODPATH_SYSTEM_PROP" ] && abort " ! system.prop not found !"
[ ! -w "$MODPATH_SYSTEM_PROP" ] && abort " ! system.prop is not writable !"

# Define the props path
MODPROP_FILES=$(find_prop_files "$MODPATH/" 1)
SYSPROP_FILES=$(find_prop_files "/" 3)

# Store the content of all prop files in a variable
MODPROP_CONTENT=$(echo "$MODPROP_FILES" | xargs cat)
SYSPROP_CONTENT=$(echo "$SYSPROP_FILES" | xargs cat)

# Function to comment property in system.prop
comment_prop() {
  prop_name="$1"
  sys_prop_val="$2"
  mod_prop_key="$3"

  ui_print " - $prop_name=$sys_prop_val, safe property."
  if ! sed -i "s/^${mod_prop_key}/# ${mod_prop_key}/" "$MODPATH_SYSTEM_PROP"; then
    ui_print " ! Warning: Failed to uncomment property $mod_prop_key"
  fi
}

# Function to remove commented property from system.prop
uncomment_prop() {
  prop_name="$1"
  sys_prop_val="$2"
  mod_prop_key="$3"

  ui_print " - $prop_name=$sys_prop_val, unsafe property…"
  if ! sed -i "s/^# ${mod_prop_key}/${mod_prop_key}/" "$MODPATH_SYSTEM_PROP"; then
    ui_print " ! Warning: Failed to comment property $mod_prop_key"
  fi
}

# Function to check and update a property
check_and_update_prop() {
  sys_prop_key="$1"
  mod_prop_key="$2"
  prop_name="$3"
  comparison="$4"

  # Get the system and module properties
  sys_prop=$(grep_prop "$sys_prop_key" "$SYSPROP_CONTENT")
  mod_prop=$(grep_prop "$mod_prop_key" "$MODPROP_CONTENT")

  # Check if sys_prop or mod_prop is empty
  if [ -z "$sys_prop" ] || [ -z "$mod_prop" ]; then
    ui_print " - $prop_name is missing in either system or module props, skipping…"
    return
  fi

  # Perform comparisons based on the operand type
  case "$comparison" in
  "eq") [ "$sys_prop" = "$mod_prop" ] 2>/dev/null && comment_prop "$prop_name" "$sys_prop" "$mod_prop_key" || uncomment_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "ne") [ "$sys_prop" != "$mod_prop" ] 2>/dev/null && comment_prop "$prop_name" "$sys_prop" "$mod_prop_key" || uncomment_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "lt") [ "$sys_prop" -lt "$mod_prop" ] 2>/dev/null && comment_prop "$prop_name" "$sys_prop" "$mod_prop_key" || uncomment_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "le") [ "$sys_prop" -le "$mod_prop" ] 2>/dev/null && comment_prop "$prop_name" "$sys_prop" "$mod_prop_key" || uncomment_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "gt") [ "$sys_prop" -gt "$mod_prop" ] 2>/dev/null && comment_prop "$prop_name" "$sys_prop" "$mod_prop_key" || uncomment_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  "ge") [ "$sys_prop" -ge "$mod_prop" ] 2>/dev/null && comment_prop "$prop_name" "$sys_prop" "$mod_prop_key" || uncomment_prop "$prop_name" "$sys_prop" "$mod_prop_key" ;;
  esac
}

# Function to initialize config with default values
init_config() {
  # Try to get values from the existing config
  device_prop=$(grep_prop "pixelprops.sensitive.device" "$MODPROP_CONTENT")
  sdk_prop=$(grep_prop "pixelprops.sensitive.sdk" "$MODPROP_CONTENT")

  # Initialize with existing values or defaults
  SAFE_DEVICE=${device_prop:-true}
  SAFE_SDK=${sdk_prop:-true}

  # If either property is missing, get user input
  if [ -z "$device_prop" ] || [ -z "$sdk_prop" ]; then
    ui_print " - Some sensitive properties not found, asking for user input…"

    # Get user input only for missing properties

    if [ -z "$device_prop" ]; then
      volume_key_event_setval "SAFE_DEVICE" true false SAFE_DEVICE
      echo "pixelprops.sensitive.device=$SAFE_DEVICE" >>"$MODPATH/config.prop"
    fi

    if [ -z "$sdk_prop" ]; then
      volume_key_event_setval "SAFE_SDK" true false SAFE_SDK
      echo "pixelprops.sensitive.sdk=$SAFE_SDK" >>"$MODPATH/config.prop"
    fi
  fi
}

# Check and update the sensitive properties based on user selection
sensitive_checks() {
  if boolval "$SAFE_DEVICE"; then
    ui_print " - Safe Mode was manually disabled for \"SAFE_DEVICE\" !"
  else
    check_and_update_prop "ro.product.product.device" "ro.product.device" "PRODUCT_DEVICE" "ne"
    check_and_update_prop "ro.product.vendor.device" "ro.product.vendor.device" "VENDOR_DEVICE" "ne"
  fi

  if boolval "$SAFE_SDK"; then
    ui_print " - Safe Mode was manually disabled for \"SAFE_SDK\" !"
  else
    check_and_update_prop "ro.product.build.version.sdk" "ro.product.build.version.sdk" "SDK" "lt"
    check_and_update_prop "ro.product.build.version.release" "ro.product.build.version.release" "BUILD_VERSION" "lt"
    check_and_update_prop "ro.product.build.version.release_or_codename" "ro.product.build.version.release_or_codename" "BUILD_VERSION_CODENAME" "lt"
  fi
}

# Running checks
ui_print "- Running Sensitive MODPROP checks…"
ui_print " ? When a property was detected as unsafe, It will be removed from the module system.prop spoof."
init_config
sensitive_checks
