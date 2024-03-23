#!/data/adb/magisk/busybox sh
# shellcheck shell=sh

export MODDIR="${0%/*}"
export MODPATH="$MODDIR"

# Module variables
MODPATH_SYSTEM_PROP="$MODPATH"/system.prop
SYS_PROP_MANUFACTURER=$(grep_prop ro.product.manufacturer)
SYS_PROP_DEVICE=$(grep_prop ro.product.device)
SYS_PROP_MODEL=$(grep_prop ro.product.model)
SYS_PROP_SDK=$(grep_prop ro.build.version.sdk)
SYS_PROP_MIN_API=$(grep_prop ro.product.first_api_level /vendor/build.prop)
MOD_PROP_MANUFACTURER=$(grep_prop ro.product.manufacturer "$MODPATH_SYSTEM_PROP");
[ -z "$MOD_PROP_MANUFACTURER" ] && MOD_PROP_MANUFACTURER=$(grep_prop ro.product.system.manufacturer "$MODPATH_SYSTEM_PROP");
MOD_PROP_DEVICE=$(grep_prop ro.product.device "$MODPATH_SYSTEM_PROP");
MOD_PROP_MODEL=$(grep_prop ro.product.model "$MODPATH_SYSTEM_PROP");
[ -z "$MOD_PROP_MODEL" ] && MOD_PROP_MODEL=$(grep_prop ro.product.system.model "$MODPATH_SYSTEM_PROP");
MOD_PROP_SDK=$(grep_prop ro.build.version.sdk "$MODPATH_SYSTEM_PROP" | grep -ohE '[0-9]{2}')
FIRST_API_LEVEL=$(grep_prop ro.product.first_api_level "$MODPATH_SYSTEM_PROP");
[ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.board.first_api_level "$MODPATH_SYSTEM_PROP");
[ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.board.api_level "$MODPATH_SYSTEM_PROP");
if [ -z "$FIRST_API_LEVEL" ]; then
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.build.version.sdk "$MODPATH_SYSTEM_PROP");
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.system.build.version.sdk "$MODPATH_SYSTEM_PROP");
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.build.version.sdk "$MODPATH_SYSTEM_PROP");
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.system.build.version.sdk "$MODPATH_SYSTEM_PROP");
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.vendor.build.version.sdk "$MODPATH_SYSTEM_PROP");
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(grep_prop ro.product.build.version.sdk "$MODPATH_SYSTEM_PROP");
fi;

# Function to check and update a property
check_and_update_prop() {
  sys_prop="$1"
  mod_prop="$2"
  prop_name="$3"
  prop_key="$4"
  comparison="$5"

  case "$comparison" in
  "eq") [ "$sys_prop" -eq "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$prop_key" || ignore_prop "$prop_name" "$sys_prop" "$prop_key" ;;
  "ne") [ "$sys_prop" -ne "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$prop_key" || ignore_prop "$prop_name" "$sys_prop" "$prop_key" ;;
  "lt") [ "$sys_prop" -lt "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$prop_key" || ignore_prop "$prop_name" "$sys_prop" "$prop_key" ;;
  "le") [ "$sys_prop" -le "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$prop_key" || ignore_prop "$prop_name" "$sys_prop" "$prop_key" ;;
  "gt") [ "$sys_prop" -gt "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$prop_key" || ignore_prop "$prop_name" "$sys_prop" "$prop_key" ;;
  "ge") [ "$sys_prop" -ge "$mod_prop" ] && update_prop "$prop_name" "$sys_prop" "$prop_key" || ignore_prop "$prop_name" "$sys_prop" "$prop_key" ;;
  esac
}

update_prop() {
  ui_print "- $1=$2, running unsafe mode"
  sed -i "s/^# $3/$3/" "$MODPATH_SYSTEM_PROP"
}

ignore_prop() {
  ui_print "- $1=$2, running safe mode"
  sed -i "s/^$3/# $3/" "$MODPATH_SYSTEM_PROP"
}

# Check and update properties
ui_print ""
check_and_update_prop "$SYS_PROP_MANUFACTURER" "$MOD_PROP_MANUFACTURER" "MANUFACTURER" "ro.product.manufacturer" "ne"
check_and_update_prop "$SYS_PROP_MODEL" "$MOD_PROP_MODEL" "MODEL" "ro.product.model" "ne"
check_and_update_prop "$SYS_PROP_DEVICE" "$MOD_PROP_DEVICE" "DEVICE" "ro.product.device" "ne"
check_and_update_prop "$SYS_PROP_SDK" "$MOD_PROP_SDK" "SDK" "ro.build.version.sdk" "lt"
check_and_update_prop "$SYS_PROP_MIN_API" "$FIRST_API_LEVEL" "FIRST_API" "ro.product.first_api_level" "lt"

ui_print "  ? When in safe mode your device will ignore to spoof the specified prop."
ui_print ""
