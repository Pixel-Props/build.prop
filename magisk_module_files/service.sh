#!/system/bin/busybox sh

MODPATH="${0%/*}"

# If MODPATH is empty or is not default modules path, use current path
[ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/' &&
  MODPATH="$(dirname "$(readlink -f "$0")")"

# Using util_functions.sh
[ -f "$MODPATH/util_functions.sh" ] && . "$MODPATH/util_functions.sh" || abort "! util_functions.sh not found!"

# Define module property config
for prop_file in "system.prop" "config.prop"; do
  prop_path="$MODPATH/$prop_file"
  prop_key_upper=$(echo "${prop_file%%.*}" | tr '[:lower:]' '[:upper:]')

  # Check whether the file exists and is writable
  [ ! -f "$prop_path" ] || [ ! -w "$prop_path" ] && abort " ! $prop_file not found or not writable !"

  # Set variable for the module property configs
  eval "MODPATH_${prop_key_upper}_PROP=\$prop_path"
done

# Define the props path and content
MODPROP_FILES=$(find_prop_files "$MODPATH/" 1)
SYSPROP_FILES=$(find_prop_files "/" 3)
MODPROP_CONTENT=$(echo "$MODPROP_FILES" | xargs cat)
SYSPROP_CONTENT=$(echo "$SYSPROP_FILES" | xargs cat)

# Property management functions
manage_prop() {
  local action=$1 prop_name=$2 mod_prop_val=$3 mod_prop_key=$4
  ui_print " - $prop_name=$mod_prop_val, ${action}ing property…"

  # Construct the sed command dynamically using eval
  local comment_cmd="s/^${mod_prop_key}/# ${mod_prop_key}/"
  local uncomment_cmd="s/^# ${mod_prop_key}/${mod_prop_key}/"
  eval "local sed_cmd=\$${action}_cmd"

  sed -i "$sed_cmd" "$MODPATH_SYSTEM_PROP" ||
    ui_print " ! Warning: Failed to $action property $mod_prop_key"
}

comment_prop() { manage_prop "comment" "$@"; }
uncomment_prop() { manage_prop "uncomment" "$@"; }

check_and_update_prop() {
  local sys_prop_key=$1 mod_prop_key=$2 prop_name=$3 comparison=$4

  # Get the system and module properties
  sys_prop=$(grep_prop "$sys_prop_key" "$SYSPROP_CONTENT")
  mod_prop=$(grep_prop "$mod_prop_key" "$MODPROP_CONTENT")

  # Check if the property exists within mod_prop
  [ -z "$mod_prop" ] && {
    ui_print " - $prop_name is missing in either system or module props, skipping…"
    return
  }

  local result
  # Perform comparisons based on the operand type
  case "$comparison" in
  eq) [ "$sys_prop" = "$mod_prop" ] && result=0 ;;
  ne) [ "$sys_prop" != "$mod_prop" ] && result=0 ;;
  lt) [ "$sys_prop" -lt "$mod_prop" ] 2>/dev/null && result=0 ;;
  le) [ "$sys_prop" -le "$mod_prop" ] 2>/dev/null && result=0 ;;
  gt) [ "$sys_prop" -gt "$mod_prop" ] 2>/dev/null && result=0 ;;
  ge) [ "$sys_prop" -ge "$mod_prop" ] 2>/dev/null && result=0 ;;
  esac

  # Patch properties based on given result
  [ "$result" = 0 ] &&
    comment_prop "$prop_name" "$mod_prop" "$mod_prop_key" ||
    uncomment_prop "$prop_name" "$mod_prop" "$mod_prop_key"
}

# Initialize config
init_config() {
  local prop_keys="device security_patch soc sdk"

  for prop_key in $prop_keys; do
    prop_val=$(grep_prop "pixelprops.sensitive.$prop_key" "$MODPROP_CONTENT")
    prop_key_upper=$(echo "$prop_key" | tr '[:lower:]' '[:upper:]')
    eval "SAFE_$prop_key_upper=\${prop_val:-true}"

    [ -z "$prop_val" ] && {
      ui_print " - Sensitive config property not found for $prop_key_upper, requesting user input…"
      volume_key_event_setval "SAFE_$prop_key_upper" true false "SAFE_$prop_key_upper"

      var_name="SAFE_$prop_key_upper"
      eval "prop_value=\$$var_name"
      echo "pixelprops.sensitive.$prop_key=$prop_value" >>"$MODPATH_CONFIG_PROP"
    }
  done
}

# Check sensitive properties
sensitive_checks() {
  function_map=$(
    cat <<EOF
DEVICE:device:ne
SECURITY_PATCH:security_patch:ne
SOC:soc:ne
SDK:sdk:lt
EOF
  )

  echo "$function_map" | while IFS=: read -r safe_var prop_type comparison; do
    eval "local safe_val=\$SAFE_$safe_var"

    if ! boolval "$safe_val"; then
      ui_print " - Safe Mode was manually disabled for \"SAFE_$safe_var\" !"
    else
      case "$prop_type" in
      device)
        check_and_update_prop "ro.product.product.device" "ro.product.device" "PRODUCT_DEVICE" "$comparison"
        check_and_update_prop "ro.product.vendor.device" "ro.product.vendor.device" "VENDOR_DEVICE" "$comparison"
        ;;
      security_patch)
        check_and_update_prop "ro.vendor.build.security_patch" "ro.vendor.build.security_patch" "VENDOR_SECURITY_PATCH" "$comparison"
        check_and_update_prop "ro.build.version.security_patch" "ro.build.version.security_patch" "BUILD_SECURITY_PATCH" "$comparison"
        ;;
      soc)
        check_and_update_prop "ro.soc.model" "ro.soc.model" "SOC_MODEL" "$comparison"
        check_and_update_prop "ro.soc.manufacturer" "ro.soc.manufacturer" "SOC_MANUFACTURER" "$comparison"
        ;;
      sdk)
        local prefixes="build product vendor vendor_dlkm system system_ext system_dlkm"
        local versions="sdk incremental release release_or_codename"

        for prefix in $prefixes; do
          for version in $versions; do
            prefix_upper=$(echo "$prefix" | tr '[:lower:]' '[:upper:]')
            version_upper=$(echo "$version" | tr '[:lower:]' '[:upper:]')

            # Construct the property name
            [ "$prefix" = "build" ] &&
              prop_name="ro.${prefix}.version.${version}" ||
              prop_name="ro.${prefix}.build.version.${version}"

            check_and_update_prop "$prop_name" "$prop_name" "${prefix_upper}_BUILD_$version_upper" "$comparison"
          done
        done
        ;;
      esac
    fi
  done
}

# Main execution
ui_print "- Running Sensitive MODPROP checks…"
ui_print " ? When a property was detected as unsafe, It will be removed / commented out from the module property."
ui_print " ? To remove a property set it to true and It will be removed / commented out from the module property."
init_config
sensitive_checks
