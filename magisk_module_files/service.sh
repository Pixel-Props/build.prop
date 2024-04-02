#!/data/adb/magisk/busybox sh

MODPATH_SYSTEM_PROP=$([ -d "$MODPATH_SYSTEM_PROP" ] || echo "${0%/*}/system.prop")

# Function to check and update a property
check_and_update_prop() {
  sys_prop_key="$1"
  mod_prop_key="$2"
  prop_name="$3"
  comparison="$4"

  sys_prop=$(get_property "$sys_prop_key")
  mod_prop=$(get_property "$mod_prop_key" "$MODPATH_SYSTEM_PROP")

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
  ui_print " - $1=$2, running unsafe mode"
  sed -i "s/^# $3/$3/" "$MODPATH_SYSTEM_PROP"
}

ignore_prop() {
  ui_print " - $1=$2, running safe mode"
  sed -i "s/^$3/# $3/" "$MODPATH_SYSTEM_PROP"
}

# Check and update properties
ui_print ""
check_and_update_prop "manufacturer" "manufacturer" "MANUFACTURER" "ne"
check_and_update_prop "model" "model" "MODEL" "ne"
check_and_update_prop "device" "device" "DEVICE" "ne"
check_and_update_prop "build.version.sdk" "build.version.sdk" "SDK" "lt"
check_and_update_prop "first_api_level" "first_api_level" "FIRST_API_LEVEL" "lt"

ui_print "  ? When in safe mode your device will ignore to spoof the specified prop."
ui_print ""
