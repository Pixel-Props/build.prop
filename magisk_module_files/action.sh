#!/system/bin/sh
MODPATH="${0%/*}"

echo ""
echo "- Building configuration file for PlayIntegrityFix / TrickyStore"

GOOGLE_APPS="com.google.android.gsf com.google.android.gms com.google.android.googlequicksearchbox"
PIF_MODULE_DIR="/data/adb/modules/playintegrityfix"
PIF_DIRS="$MODPATH/pif.json $PIF_MODULE_DIR/pif.json"
PIF_LIST="DEBUG spoofProps spoofProvider spoofSignature MANUFACTURER BRAND MODEL DEVICE PRODUCT FINGERPRINT ID SECURITY_PATCH DEVICE_INITIAL_SDK_INT TYPE TAGS"

# Function to find build & system properties within a specified directory.
find_prop_files() {
  dir="$1"
  maxdepth="$2"
  maxdepth=${maxdepth:-3}

  find "$dir" -maxdepth "$maxdepth" -type f \( -name 'build.prop' -o -name 'system.prop' \) -print 2>/dev/null
}

# Function to grep a property value from a list of files
grep_prop() {
  PROP="$1"
  shift
  FILES_or_VAR="$@"

  if [ -n "$FILES_or_VAR" ]; then
    echo "$FILES_or_VAR" | grep -m1 "^$PROP=" 2>/dev/null | cut -d= -f2- | head -n 1
  fi
}

# Define the props path
MODPROP_FILES=$(find_prop_files "$MODPATH/" 1)
SYSPROP_FILES=$(find_prop_files "/" 2)

# Store the content of all prop files in a variable
MODPROP_CONTENT=$(echo "$MODPROP_FILES" | xargs cat)
SYSPROP_CONTENT=$(echo "$SYSPROP_FILES" | xargs cat)

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
    echo " ? Cleanned $google_app"
  done
  # settings get/put --user $(am get-current-user) secure android_id
}

# PlayIntegrityFix (PIF.json)
PlayIntegrityFix() {
  DEBUG=false
  spoofProps=true
  spoofProvider=true
  spoofSignature=false
  MODEL=$(grep_prop "ro.product.model" "$MODPROP_CONTENT")
  BRAND=$(grep_prop "ro.product.brand" "$MODPROP_CONTENT")
  MANUFACTURER=$(grep_prop "ro.product.manufacturer" "$MODPROP_CONTENT")
  DEVICE=$(grep_prop "ro.product.product.device" "$MODPROP_CONTENT")
  # RELEASE=$(grep_prop "ro.product.build.version.release" "$MODPROP_CONTENT")
  ID=$(grep_prop "ro.product.build.id" "$MODPROP_CONTENT")
  # INCREMENTAL=$(grep_prop "ro.build.version.incremental" "$MODPROP_CONTENT")
  PRODUCT=$(grep_prop "ro.product.product.name" "$MODPROP_CONTENT")
  DEVICE_INITIAL_SDK_INT=$(grep_prop "ro.product.first_api_level" "$SYSPROP_CONTENT")
  [ -z "$DEVICE_INITIAL_SDK_INT" ] && DEVICE_INITIAL_SDK_INT=$(grep_prop "ro.product.build.version.sdk" "$SYSPROP_CONTENT")
  FINGERPRINT=$(grep_prop "ro.product.build.fingerprint" "$MODPROP_CONTENT")
  SECURITY_PATCH=$(grep_prop "ro.vendor.build.security_patch" "$MODPROP_CONTENT")
  # BUILD_UTC=$(grep_prop "ro.product.build.date.utc" "$MODPROP_CONTENT")
  # [ "$BUILD_UTC" -gt 1520257020 ] && PIF_LIST="$PIF_LIST SECURITY_PATCH" # < March 2018 build date required
  TYPE=$(grep_prop "ro.product.build.type" "$MODPROP_CONTENT")
  TAGS=$(grep_prop "ro.product.build.tags" "$MODPROP_CONTENT")

  echo " - Building PlayIntegrityFix (PIF.json) properties…"

  # Set location of pif.json to of the current working directory
  CWD_PIF="$(readlink -f "$PWD")/pif.json"
  shift

  # Delete old CWD pif file
  [ -f "$CWD_PIF" ] && rm -f "$CWD_PIF"

  update_count=0
  if [ -d "$PIF_MODULE_DIR" ]; then
    case "$PRODUCT" in
    *beta*)
      echo " - Building PIF.json from current module properties…"

      # Build the JSON object
      build_json >"$CWD_PIF"

      # Handle Google apps
      # handle_google_apps

      for PIF_DIR in $PIF_DIRS; do
        if cmp "$CWD_PIF" "$PIF_DIR" >/dev/null; then # Compare new PIF with existing PIF file
          echo " - No changes detected in \"$PIF_DIR\"."
        else
          mv "$PIF_DIR" "${PIF_DIR}.old"
          cp "$CWD_PIF" "$PIF_DIR"
          echo " ++ Config file has been updated and saved to \"$PIF_DIR\"."
          update_count=$((update_count + 1))
        fi
      done
      ;;
    *)
      echo " - Non BETA property, Downloading PIF.json in order to pass integrity…"
      curl -L -o "$CWD_PIF" -# "https://raw.githubusercontent.com/chiteroman/PlayIntegrityFix/main/module/pif.json"

      for PIF_DIR in $PIF_DIRS; do
        if cmp "$CWD_PIF" "$PIF_DIR" >/dev/null; then # Compare new PIF with existing PIF file
          echo " - No changes detected in \"$PIF_DIR\"."
        else
          mv "$PIF_DIR" "${PIF_DIR}.old"
          cp "$CWD_PIF" "$PIF_DIR"
          echo " ++ Config file has been updated and saved to \"$PIF_DIR\"."
          update_count=$((update_count + 1))
        fi
      done
      ;;
    esac

    # Show instructions only after we modified the PIF
    if [ $update_count -gt 0 ]; then
      echo "  ? Please disconnect your device from your Google account: https://myaccount.google.com/device-activity"
      echo "  ? Clean the data from Google system apps such as GMS, GSF, and Google apps."
      echo "  ? Then restart and make sure to reconnect to your device, Make sure if your device is logged as \"$MODEL\"."
      echo "  ? More info: https://t.me/PixelProps/157"
    fi
  else
    echo " - PlayIntegrityFix not found in your modules."
  fi
}

# TrickyStore (target.txt)
TrickyStoreTarget() {
  # Check if the directory tricky_store exists
  if [ -d "/data/adb/tricky_store" ]; then
    echo " - Building TrickyStore (target.txt) packages…"

    # Use pm list packages to get a list of installed packages
    PACKAGES=$(pm list packages | sed 's/package://g')

    # Check if your TEE is broken
    if grep -qE "^teeBroken=(true|1)$" /data/adb/tricky_store/tee_status; then
      echo "  ! Hardware Attestation support not available (teeBroken=true)"
      echo "  ! Fallback to Broken TEE Support mode (!)"
      # If teeBroken is true or 1, add "!" before each package name
      PACKAGES=$(echo "$PACKAGES" | sed 's/^/!/g')
    fi

    # Write the package list to the target file
    echo "$PACKAGES" >/data/adb/tricky_store/target.txt
    echo " ++ Target file has been updated and saved to \"/data/adb/tricky_store/target.txt\""
  fi
}

# Calling functions
PlayIntegrityFix
TrickyStoreTarget
