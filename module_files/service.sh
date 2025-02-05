#!/system/bin/busybox sh

MODPATH="${0%/*}"

# If MODPATH is empty or is not default modules path, use current path
[ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/' &&
  MODPATH="$(dirname "$(readlink -f "$0")")"

# Using util_functions.sh
[ -f "$MODPATH/util_functions.sh" ] && . "$MODPATH/util_functions.sh" || abort "! util_functions.sh not found!"

# Wait for boot completion
while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 2; done

# Wait for the device to decrypt (if it's encrypted) when phone is unlocked once.
until [ -d "/sdcard/Android" ]; do sleep 3; done

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
  local prop_keys="device security_patch soc sdk props pihooks"

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

# Check module sensitive properties
mod_sensitive_checks() {
  ui_print "- Running Sensitive MODPROP checks…"

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
        check_and_update_prop "ro.product.first_api_level" "ro.product.first_api_level" "FIRST_API_LEVEL" "$comparison"

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

# Check system sensitive properties
sys_sensitive_checks() {
  # Check if sensitive_props module exists
  if [ -d "/data/adb/modules/sensitive_props" ]; then
    abort "Sensitive Props module is already present, Skipping !" false
  else
    ui_print "- Running Sensitive SYSPROP checks…"

    ### Props ###

    # Periodically hexpatch delete custom ROM props
    while true; do
      hexpatch_deleteprop "LSPosed" \
        "marketname" "custom.device" "modversion" \
        "lineage" "aospa" "pixelexperience" "evolution" "pixelos" "pixelage" "crdroid" "crDroid" "aospa" \
        "aicp" "arter97" "blu_spark" "cyanogenmod" "deathly" "elementalx" "elite" "franco" "hadeskernel" \
        "morokernel" "noble" "optimus" "slimroms" "sultan" "aokp" "bharos" "calyxos" "calyxOS" "divestos" \
        "emteria.os" "grapheneos" "indus" "iodéos" "kali" "nethunter" "omnirom" "paranoid" "replicant" \
        "resurrection" "rising" "remix" "shift" "volla" "icosa" "kirisakura" "infinity" "Infinity"
      # add more...

      # Wait for 1 hour before the next check.
      sleep 3600
    done &

    # Fix display properties to remove custom ROM references
    replace_value_resetprop ro.build.flavor "lineage_" ""
    replace_value_resetprop ro.build.flavor "userdebug" "user"
    replace_value_resetprop ro.build.display.id "lineage_" ""
    replace_value_resetprop ro.build.display.id "userdebug" "user"
    replace_value_resetprop ro.build.display.id "dev-keys" "release-keys"
    replace_value_resetprop vendor.camera.aux.packagelist "lineageos." ""
    replace_value_resetprop ro.build.version.incremental "eng." ""

    # Realme fingerprint fix
    check_resetprop ro.boot.flash.locked 1
    check_resetprop ro.boot.realme.lockstate 1
    check_resetprop ro.boot.realmebootstate green

    # Oppo fingerprint fix
    check_resetprop ro.boot.vbmeta.device_state locked
    check_resetprop vendor.boot.vbmeta.device_state locked

    # OnePlus display/fingerprint fix
    check_resetprop ro.is_ever_orange 0
    check_resetprop vendor.boot.verifiedbootstate green

    # OnePlus/Oppo display fingerprint fix on OOS/ColorOS 12+
    check_resetprop ro.boot.veritymode enforcing
    check_resetprop ro.boot.verifiedbootstate green

    # Samsung warranty bit fix
    for prop in ro.boot.warranty_bit ro.warranty_bit ro.vendor.boot.warranty_bit ro.vendor.warranty_bit; do
      check_resetprop "$prop" 0
    done

    ### General adjustments ###

    # Process prefixes for build properties
    for prefix in bootimage odm odm_dlkm oem product system system_ext vendor vendor_dlkm; do
      check_resetprop ro.${prefix}.build.type user
      check_resetprop ro.${prefix}.keys release-keys
      check_resetprop ro.${prefix}.build.tags release-keys

      # Remove engineering ROM
      replace_value_resetprop ro.${prefix}.build.version.incremental "eng." ""
    done

    # Maybe reset properties based on conditions (recovery boot mode)
    for prop in ro.bootmode ro.boot.bootmode ro.boot.mode vendor.bootmode vendor.boot.bootmode vendor.boot.mode; do
      maybe_resetprop "$prop" recovery unknown
    done

    # MIUI cross-region flash adjustments
    for prop in ro.boot.hwc ro.boot.hwcountry; do
      maybe_resetprop "$prop" CN GLOBAL
    done

    # SafetyNet/banking app compatibility
    check_resetprop sys.oem_unlock_allowed 0
    check_resetprop ro.oem_unlock_supported 0
    check_resetprop net.tethering.noprovisioning true

    # Init.rc adjustment
    check_resetprop init.svc.flash_recovery stopped

    # Fake encryption status
    check_resetprop ro.crypto.state encrypted

    # Secure boot and device lock settings
    check_resetprop ro.secure 1
    check_resetprop ro.secureboot.devicelock 1
    check_resetprop ro.secureboot.lockstate locked

    # Disable debugging and adb over network
    check_resetprop ro.force.debuggable 0
    check_resetprop ro.debuggable 0
    check_resetprop ro.adb.secure 1

    # Native Bridge (could break some features, appdome?)
    # deleteprop ro.dalvik.vm.native.bridge

    ### System Settings ###

    # Fix Restrictions on non-SDK interface and disable developer options
    for global_setting in hidden_api_policy hidden_api_policy_pre_p_apps hidden_api_policy_p_apps; do # adb_enabled development_settings_enabled tether_dun_required
      settings delete global "$global_setting" >/dev/null 2>&1
    done

    # Disable untrusted touches
    for namespace in global system secure; do
      settings put "$namespace" "block_untrusted_touches" 0 >/dev/null 2>&1
    done

    ### File Permissions ###

    # Hiding SELinux | Use toybox to protect *stat* access time reading
    [ -f /sys/fs/selinux/enforce ] && [ "$(toybox cat /sys/fs/selinux/enforce)" == "0" ] && {
      set_permissions /sys/fs/selinux/enforce 640
      set_permissions /sys/fs/selinux/policy 440
    }

    # Find install-recovery.sh and set permissions
    find /vendor/bin /system/bin -name install-recovery.sh | while read -r file; do
      set_permissions "$file" 440
    done

    # Set permissions for other files/directories
    set_permissions /proc/cmdline 440
    set_permissions /proc/net/unix 440
    set_permissions /system/addon.d 750
    set_permissions /sdcard/TWRP 750
  fi
}

sys_sensitive_pihooks_checks() {
  # Get initial Pihooks property names.
  pihook_props=$(getprop | grep 'pihooks' | cut -d ':' -f 1 | tr -d '[]')
  PIF_MODULE_DIR="/data/adb/modules/playintegrityfix"
  use_pihooks=1

  # Check if Pihooks poperties exist and PIF is not used.
  if [[ -d "$PIF_MODULE_DIR" ]] && [[ -s "$PIF_MODULE_DIR/module.prop" ]]; then
    use_pihooks=0
    ui_print "- PlayIntegrityFix module detected, Disabling PIHOOKS spoofing…"
  fi

  # Check if Pihooks properties exist.
  if [ -z "$pihook_props" ]; then
    ui_print "- No pihooks properties found (internal spoofing)"
    ui_print " ! Use PlayIntegrityFix instead ?"
  else
    ui_print "- Running Sensitive PIHOOKS checks (internal spoofing)…"

    # Build properties
    BRAND=$(grep_prop "ro.product.brand" "$MODPROP_CONTENT")
    MODEL=$(grep_prop "ro.product.model" "$MODPROP_CONTENT")
    DEVICE=$(grep_prop "ro.product.device" "$MODPROP_CONTENT")
    MANUFACTURER=$(grep_prop "ro.product.manufacturer" "$MODPROP_CONTENT")
    PRODUCT=$(grep_prop "ro.product.product.name" "$MODPROP_CONTENT")
    FINGERPRINT=$(grep_prop "ro.product.build.fingerprint" "$MODPROP_CONTENT")
    SECURITY_PATCH=$(grep_prop "ro.vendor.build.security_patch" "$MODPROP_CONTENT")
    DEVICE_INITIAL_SDK_INT=$(grep_prop "ro.product.first_api_level" "$SYSPROP_CONTENT")
    [ -z "$DEVICE_INITIAL_SDK_INT" ] && DEVICE_INITIAL_SDK_INT=$(grep_prop "ro.product.build.version.sdk" "$SYSPROP_CONTENT")
    BUILD_ID=$(grep_prop "ro.product.build.id" "$MODPROP_CONTENT")
    BUILD_TAGS=$(grep_prop "ro.product.build.tags" "$MODPROP_CONTENT")
    BUILD_TYPE=$(grep_prop "ro.product.build.type" "$MODPROP_CONTENT")

    update_ph_count=0
    # Essential properties for integrity (PIF-less-PIF mode)
    essential_props="model manufacturer product fingerprint security_patch initial_sdk"
    # Calculate the total number of essential props dynamically
    total_essential_props=$(echo "$essential_props" | wc -w)

    # Set string values responsible for spoofing PropImitationHooks.
    for prop in $pihook_props; do
      prop_value=$(getprop "$prop")
      prop_lower=$(echo "$prop" | tr '[:upper:]' '[:lower:]')
      final_value="" # Disable by default

      # Check if it's a boolean value using is_bool.
      if ! is_bool "$prop_value"; then
        # Check and apply the proper values
        case "$prop_lower" in
        *"brand"*) final_value="$BRAND" ;;
        *"model"*) final_value="$MODEL" ;;
        *"device"*) final_value="$DEVICE" ;;
        *"manufacturer"*) final_value="$MANUFACTURER" ;;
        *"product"*) final_value="$PRODUCT" ;;
        *"fingerprint"*) final_value="$FINGERPRINT" ;;
        *"security_patch"*) final_value="$SECURITY_PATCH" ;;
        *"first_api"* | *"initial_sdk"*) final_value="$DEVICE_INITIAL_SDK_INT" ;;
        *"id"*) final_value="$BUILD_ID" ;;
        *"tags"*) final_value="$BUILD_TAGS" ;;
        *"type"*) final_value="$BUILD_TYPE" ;;
        esac

        # Check if this is one of the essential properties
        for essential_prop in $essential_props; do
          if [[ "$prop_lower" == *"$essential_prop"* && -n "$final_value" ]]; then
            essential_props_set=$((essential_props_set + 1))
            break # No need to check other essential props for this pihook prop
          fi
        done

        # Reset the property
        check_resetprop "$prop" "$final_value"
        ui_print " ? Property $prop set to \"$final_value\""
      fi

      # If the value is not empty add to update_ph_count
      [ -n "$final_value" ] && update_ph_count=$((update_ph_count + 1))
    done

    # Warn the user if essential properties for PIF-less spoofing are not set
    if [ "$essential_props_set" -lt "$total_essential_props" ]; then
      ui_print "***************************************"
      ui_print " ! Warning: Not all essential properties for PIF-less spoofing are set. This means that relying solely on PIHooks for spoofing might not be approriate. We recommend using PlayIntegrityFix instead, as it provides more comprehensive spoofing capabilities. As a result, relevant PIHooks features will be disabled."
      ui_print "***************************************"
    fi

    # Set boolean values responsible for enabling or disabling the feature.
    for prop in $pihook_props; do
      prop_value=$(getprop "$prop")
      prop_lower=$(echo "$prop" | tr '[:upper:]' '[:lower:]')
      final_value="0" # Disable by default

      # Check if it's a boolean value using is_bool.
      if is_bool "$prop_value"; then
        # Use essential_props_set to determine if spoofing is likely successful
        boolval "$use_pihooks" && [ "$essential_props_set" -ge "$total_essential_props" ] && final_value="1"

        # If the prop contains "disable" revert the disabled state, from false to true.
        # Don't revert the check if prop name contains checks irrelevent to integrity.
        if [[ "$prop_lower" == *"disable"* ]] &&
          [[ ! "$prop_lower" == *"game"* ]] &&
          [[ ! "$prop_lower" == *"photo"* ]] &&
          [[ ! "$prop_lower" == *"netflix"* ]]; then
          final_value="1" # Disable by default
          boolval "$use_pihooks" && [ "$essential_props_set" -ge "$total_essential_props" ] && final_value="0"
        fi

        # Reset the property
        check_resetprop "$prop" "$final_value"
        ui_print " ? Property $prop set to \"$final_value\" ($(boolval "$final_value" && echo enabled || echo disabled))"
      fi
    done
  fi
}

# Main execution
init_config
mod_sensitive_checks
boolval "$SAFE_PROPS" && sys_sensitive_checks
boolval "$SAFE_PIHOOKS" && sys_sensitive_pihooks_checks
