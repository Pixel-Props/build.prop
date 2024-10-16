#!/system/bin/sh

ui_print ""
ui_print "- Building configuration file for PlayIntegrityFix / TrickyStore"

GOOGLE_APPS="com.google.android.gsf com.google.android.gms com.google.android.googlequicksearchbox"
PIF_MODULE_DIR="/data/adb/modules/playintegrityfix"
PIF_DIRS="${0%/*}/pif.json $PIF_MODULE_DIR/pif.json"
PIF_LIST="DEBUG spoofProps spoofProvider spoofSignature MANUFACTURER BRAND MODEL DEVICE INCREMENTAL PRODUCT FINGERPRINT ID DEVICE_INITIAL_SDK_INT"

# Function to build JSON object
build_json() {
  echo '{'
  for PROP in $PIF_LIST; do
    printf "\"%s\": \"%s\",\n" "$PROP" "$(eval "echo \$$PROP")"
  done | sed '$s/,//'
  echo '}'
}

# Function to handle Google apps
handle_google_apps() {
  for google_app in $GOOGLE_APPS; do
    su -c am force-stop "$google_app"
    # TODO: Automate sign-out from Device Activity #
    su -c pm clear "$google_app"
    ui_print " ? Cleanned $google_app"
  done
  # settings get/put --user $(am get-current-user) secure android_id
}

# PlayIntegrityFix (PIF.json)
PlayIntegrityFix() {
  DEBUG=false
  spoofProps=true
  spoofProvider=true
  spoofSignature=false
  MODEL=$(get_property "model" "$MODPATH_SYSTEM_PROP")
  BRAND=$(get_property "brand" "$MODPATH_SYSTEM_PROP")
  MANUFACTURER=$(get_property "manufacturer" "$MODPATH_SYSTEM_PROP")
  DEVICE=$(get_property "device" "$MODPATH_SYSTEM_PROP")
  # RELEASE=$(get_property "version.release" "$MODPATH_SYSTEM_PROP")
  ID=$(get_property "build.id" "$MODPATH_SYSTEM_PROP")
  INCREMENTAL=$(get_property "version.incremental" "$MODPATH_SYSTEM_PROP")
  PRODUCT=$(get_property "name" "$MODPATH_SYSTEM_PROP")
  DEVICE_INITIAL_SDK_INT=$(get_property "first_api_level" "$MODPATH_SYSTEM_PROP")
  [ -z "$DEVICE_INITIAL_SDK_INT" ] && DEVICE_INITIAL_SDK_INT=$(get_property "build.version.sdk" "$MODPATH_SYSTEM_PROP")
  FINGERPRINT=$(get_property "build.fingerprint" "$MODPATH_SYSTEM_PROP")
  SECURITY_PATCH=$(get_property "build.security_patch" "$MODPATH_SYSTEM_PROP")
  # BUILD_UTC=$(get_property "build.date.utc" "$MODPATH_SYSTEM_PROP")
  # [ "$BUILD_UTC" -gt 1520257020 ] && PIF_LIST="$PIF_LIST SECURITY_PATCH" # < March 2018 build date required
  # TYPE=$(get_property "build.type" "$MODPATH_SYSTEM_PROP")
  # TAGS=$(get_property "build.tags" "$MODPATH_SYSTEM_PROP")

  ui_print " - Building PlayIntegrityFix (PIF.json) properties…"

  if [ -d "$PIF_MODULE_DIR" ]; then
    CWD_PIF="$(readlink -f "$PWD")/pif.json"
    shift

    # Delete old CWD pif file
    [ -f "$CWD_PIF" ] && rm -f "$CWD_PIF"

    # Build the JSON object
    build_json >"$CWD_PIF"

    # Handle Google apps
    # handle_google_apps

    update_count=0
    for PIF_DIR in $PIF_DIRS; do
      if cmp "$CWD_PIF" "$PIF_DIR" >/dev/null; then # Compare new PIF with existing PIF file
        ui_print " - No changes detected in \"$PIF_DIR\"."
      else
        mv "$PIF_DIR" "${PIF_DIR}.old"
        cp "$CWD_PIF" "$PIF_DIR"
        ui_print " ++ Config file has been updated and saved to \"$PIF_DIR\""
        update_count=$((update_count + 1))
      fi
    done

    # Shoz instructions only after we modified the pif
    if [ $update_count -gt 0 ]; then
      ui_print "  ? Please disconnect your device from your Google account: https://myaccount.google.com/device-activity"
      ui_print "  ? Clean the data from Google system apps such as GMS, GSF, and Google apps."
      ui_print "  ? Then restart and make sure to reconnect to your device, Make sure if your device is logged as \"$MODEL\"."
      ui_print "  ? More info: https://t.me/PixelProps/157"
    fi
  else
    ui_print " - PlayIntegritySpoof does not met device or is disabled."

    # Loop true each PIF dirs
    for PIF_DIR in $PIF_DIRS; do
      # If has backup restore it
      [ -f "${PIF_DIR}.old" ] && mv "${PIF_DIR}.old" "$PIF_DIR"

      # If the pif.json is missing then we create one from maintained project
      if [ ! -f "$PIF_DIR" ]; then
        ui_print " ++ Missing $PIF_DIR, Downloading stable one for you."
        wget -O -q --show-progress "$PIF_DIR" "https://raw.githubusercontent.com/chiteroman/PlayIntegrityFix/main/module/pif.json"
      fi
    done
  fi
}

# TrickyStore (target.txt)
TrickyStoreTarget() {
  # Check if the directory tricky_store exists
  if [ -d "/data/adb/tricky_store" ]; then
    ui_print " - Building TrickyStore (target.txt) packages…"

    # Use pm list packages to get a list of installed packages
    PACKAGES=$(pm list packages | sed 's/package://g')

    # Check if your TEE is broken
    if grep -qE "^teeBroken=(true|1)$" /data/adb/tricky_store/tee_status; then
      ui_print "  ! Hardware Attestation support not available (teeBroken=true)"
      ui_print "  ! Fallback to Broken TEE Support mode (!)"
      # If teeBroken is true or 1, add "!" before each package name
      PACKAGES=$(echo "$PACKAGES" | sed 's/^/!/g')
    fi

    # Write the package list to the target file
    echo "$PACKAGES" >/data/adb/tricky_store/target.txt

    ui_print " ++ Target file has been updated and saved to \"/data/adb/tricky_store/target.txt\""
  fi
}

# Calling functions
PlayIntegrityFix
TrickyStoreTarget
