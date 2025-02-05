#!/system/bin/busybox sh
MODPATH="${0%/*}"

# If MODPATH is empty or is not default modules path, use current path
[ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/' &&
  MODPATH="$(dirname "$(readlink -f "$0")")"

# Using util_functions.sh
[ -f "$MODPATH"/util_functions.sh ] && . "$MODPATH"/util_functions.sh || abort "! util_functions.sh not found!"

# Define the props path and content
MODPROP_FILES=$(find_prop_files "$MODPATH/" 1)
SYSPROP_FILES=$(find_prop_files "/" 2)
MODPROP_CONTENT=$(echo "$MODPROP_FILES" | xargs cat)
SYSPROP_CONTENT=$(echo "$SYSPROP_FILES" | xargs cat)

# Store the content of all prop files in a variable
MODPROP_CONTENT=$(echo "$MODPROP_FILES" | xargs cat)
SYSPROP_CONTENT=$(echo "$SYSPROP_FILES" | xargs cat)

# Function to build a JSON object from a list of properties.
build_json() {
  echo '{'
  for PROP in $1; do
    printf "\"%s\": \"%s\",\n" "$PROP" "$(eval "echo \$$PROP")"
  done | sed '$s/,//'
  echo '}'
}

# Function to handle Google apps
handle_google_apps() {
  GOOGLE_APPS="com.google.android.gsf com.google.android.gms com.google.android.googlequicksearchbox"

  for google_app in $GOOGLE_APPS; do
    su -c am force-stop "$google_app"
    # TODO: Automate sign-out from Device Activity #
    am broadcast -a android.settings.ACTION_BLUETOOTH_PRIVATE_DATA_GRANTED --es package "$google_app" --ei value 0
    am broadcast -a android.settings.ACTION_BLUETOOTH_PRIVATE_DATA_GRANTED --es package "$google_app" --ei value 1
    su -c pm clear "$google_app"
    ui_print " ? Cleanned $google_app"
  done
  # settings get/put --user $(am get-current-user) secure android_id
}

# PlayIntegrityFix (PIF.json)
PlayIntegrityFix() {
  PIF_MODULE_DIR="/data/adb/modules/playintegrityfix"
  PIF_DIRS="$PIF_MODULE_DIR/pif.json"

  # Check if PIF_MODULE_DIR is valid and module.prop exists and is not empty
  # Then check if it's an Official version of PlayIntegrityFix
  if [[ -z "$PIF_MODULE_DIR" ]] || [[ ! -s "$PIF_MODULE_DIR/module.prop" ]]; then
    abort "PlayIntegrityFix module is missing or is not accessible, Skipping !" false
  elif grep -q "Fork" "$PIF_MODULE_DIR/module.prop"; then
    abort "Detected a Fork version of PlayIntegrityFix, Please install the official version" false
  else
    ui_print " - Detected an official version of PlayIntegrityFix, Proceeding Building PIF.json for official version…"

    # List of properties to include in the PIF.json file
    PIF_LIST="MODEL MANUFACTURER FINGERPRINT SECURITY_PATCH DEVICE_INITIAL_SDK_INT"

    # Build properties
    MODEL=$(grep_prop "ro.product.model" "$MODPROP_CONTENT")
    MANUFACTURER=$(grep_prop "ro.product.manufacturer" "$MODPROP_CONTENT")
    PRODUCT=$(grep_prop "ro.product.product.name" "$MODPROP_CONTENT")
    FINGERPRINT=$(grep_prop "ro.product.build.fingerprint" "$MODPROP_CONTENT")
    SECURITY_PATCH=$(grep_prop "ro.vendor.build.security_patch" "$MODPROP_CONTENT")
    DEVICE_INITIAL_SDK_INT=$(grep_prop "ro.product.first_api_level" "$SYSPROP_CONTENT")
    [ -z "$DEVICE_INITIAL_SDK_INT" ] && DEVICE_INITIAL_SDK_INT=$(grep_prop "ro.product.build.version.sdk" "$SYSPROP_CONTENT")

    # Set location of pif.json to of the current working directory
    CWD_PIF="$MODPATH"/pif.json
    shift

    # Delete old CWD pif file
    [ -f "$CWD_PIF" ] && rm -f "$CWD_PIF"

    update_count=0
    case "$PRODUCT" in
    *beta*)
      ui_print "  - Building PlayIntegrityFix PIF.json from current (BETA) module properties…"

      # Build the JSON object
      build_json "$PIF_LIST" >"$CWD_PIF"
      ;;
    *)
      ui_print "  - Non BETA module detected"
      ui_print "  - Download the PIF.json from GitHub? (chiteroman/PlayIntegrityFix)"

      # Ask whether to download PIF.json from chiteroman's GitHub or build one yourself
      volume_key_event_setval "DOWNLOAD_PIF_GITHUB" true false "ACTION_DOWNLOAD_PIF_GITHUB"

      # TODO: Not sure if i should add support for config.prop here (in case no HW keys present) ?

      # Either download the PIF.json from chiteroman's GitHub or build one yourself
      if boolval "$ACTION_DOWNLOAD_PIF_GITHUB"; then
        download_file "https://raw.githubusercontent.com/chiteroman/PlayIntegrityFix/main/module/pif.json" "$CWD_PIF"
      else
        ui_print " - Crawling the latest Google Pixel Beta OTA Releases…"

        # Download Generic System Image (GSI) HTML
        download_file https://developer.android.com/topic/generic-system-image/releases DL_GSI_HTML

        # Extract release date from the text closest to the "(Beta)" string and convert to YYYY-MM-DD format
        RELEASE_DATE="$(date -D '%B %e, %Y' -d "$(grep -m1 -o 'Date:.*' DL_GSI_HTML | cut -d\  -f2-4)" '+%Y-%m-%d' | head -n1)"

        # Extract the release version from the link closest to the "(Beta)" string
        RELEASE_VERSION="$(awk '/\(Beta\)/ {flag=1} /versions/ && flag {print; flag=0}' DL_GSI_HTML | sed -n 's/.*\/versions\/\([0-9]*\).*/\1/p' | head -n1)"

        # Extract the build ID from the text closest to the "(Beta)" string
        RELEASE_IDS="$(awk '/\(Beta\)/ {flag=1} /Build:/ && flag {print; flag=0}' DL_GSI_HTML | sed -n 's/.*Build: \([A-Z0-9.]*\).*/\1/p')"

        # Print the header with the release date
        ui_print "  - Latest Available Beta Releases ($RELEASE_DATE)"

        # Initialize an empty string for the release list
        RELEASE_LIST=""

        # Loop through each unique ID
        for ID in $RELEASE_IDS; do
          # Find the corresponding release version for the current ID
          RELEASE_VERSION=$(awk -v id="$ID" '$0 ~ id {flag=1} /Android [0-9]+/ && flag {print; flag=0}' DL_GSI_HTML | sed -n 's/.*Android \([0-9]*\).*/\1/p' | head -n1)

          # Extract the incremental value (based on the ID)
          INCREMENTAL=$(grep -o "$ID-[0-9]*-" DL_GSI_HTML | sed "s/$ID-//g" | sed 's/-//g' | head -n1)

          # Build the release info for user selection
          RELEASE_INFO="A$RELEASE_VERSION-$ID-$INCREMENTAL"

          # Append the release info to the string
          [ -z "$RELEASE_LIST" ] &&
            RELEASE_LIST="$RELEASE_INFO" ||
            RELEASE_LIST="$RELEASE_LIST $RELEASE_INFO"

          # Print the output for the current ID
          ui_print "   - Android Version: $RELEASE_VERSION ($ID) [$INCREMENTAL]"
        done

        # Use volume key events to select a release from list
        volume_key_event_setoption "RELEASE" "$RELEASE_LIST" "SELECTED_RELEASE"

        # Set the selected release id, version, incremental
        SELECTED_RELEASE_ID=$(echo "$SELECTED_RELEASE" | cut -d- -f2)
        SELECTED_RELEASE_VERSION=$(echo "$SELECTED_RELEASE" | cut -d- -f1 | tr -d 'A')
        SELECTED_RELEASE_INCREMENTAL=$(echo "$SELECTED_RELEASE" | cut -d- -f3)

        # Download the OTA Image Download page
        download_file "https://developer.android.com/about/versions/$SELECTED_RELEASE_VERSION/download-ota" DL_OTA_HTML

        # Build lists of supported models and codenames from the OTA Image Download page
        DEVICE_LIST="$(grep -A1 'tr id=' DL_OTA_HTML | awk -F '[<>"]' '
            /tr id=/ { id = $3 }
            /<td>/ {
                devices = devices ? devices sprintf(",%s (%s)", $3, id) : sprintf("%s (%s)", $3, id)
            }
            END { print devices }
        ')"

        CODENAME_LIST="$(grep -A1 'tr id=' DL_OTA_HTML | awk -F '[<>"]' '
          /tr id=/ {
              codenames = codenames ? codenames "," $3 : $3
          }
          END { print codenames }
      ')"

        # Show a list of device with proper format
        ui_print "  - Devices Available:"
        echo "$DEVICE_LIST" | tr ',' '\n' | while read -r device; do
          ui_print "   - $device"
        done

        # Use volume key events to select a device by its codename
        volume_key_event_setoption "CODENAME" "$(echo "$CODENAME_LIST" | tr ',' ' ')" "SELECTED_CODENAME"

        # Get the device MODEL name from the selected CODENAME using DEVICE_LIST
        SELECTED_MODEL=$(echo "$DEVICE_LIST" | tr ',' '\n' | awk -F'[(,]' -v c="$SELECTED_CODENAME" '$0~c{print $1}')

        # Build security patch from OTA release date
        SECURITY_PATCH_DATE="${RELEASE_DATE%-*}"-05

        # An attempt at fixing Baklava
        SELECTED_RELEASE_VERSION_OR_CODENAME=$([ "$SELECTED_RELEASE_VERSION" -gt 15 ] && echo "Baklava" || echo "$SELECTED_RELEASE_VERSION")

        # List of properties to include in the PIF.json file
        PIF_LIST="MODEL MANUFACTURER FINGERPRINT SECURITY_PATCH DEVICE_INITIAL_SDK_INT"

        # Build properties
        MODEL="$SELECTED_MODEL"
        MANUFACTURER="Google"
        FINGERPRINT="google/${SELECTED_CODENAME}_beta/$SELECTED_CODENAME:$SELECTED_RELEASE_VERSION_OR_CODENAME/$SELECTED_RELEASE_ID/$SELECTED_RELEASE_INCREMENTAL:user/release-keys"
        SECURITY_PATCH="$SECURITY_PATCH_DATE"

        # Build the JSON object
        build_json "$PIF_LIST" >"$CWD_PIF"

        # Clean the downloaded files
        rm -f DL_*_HTML
      fi
      ;;
    esac

    # Compares the newly generated PIF configuration file with existing ones and updates them if necessary.
    for PIF_DIR in $PIF_DIRS; do
      # Compares the newly generated target configuration file with existing ones and updates them if necessary.
      if [ ! -s "$CWD_PIF" ]; then
        ui_print "  ! Built PIF file does not exist or is empty."
      elif [ ! -s "$PIF_DIR" ]; then
        update_count=$((update_count + 1))

        # Target file does not exist or is empty, so copy the new one
        cp "$CWD_PIF" "$PIF_DIR"
        ui_print "  ++ Config file has been created at \"$PIF_DIR\"."
      elif ! cmp -s "$CWD_PIF" "$PIF_DIR"; then
        update_count=$((update_count + 1))

        # Target file exists and is different, back up the old one and update
        mv "$PIF_DIR" "${PIF_DIR}.old" 2>/dev/null # 2>/dev/null suppresses the error if it does not exist
        cp "$CWD_PIF" "$PIF_DIR"
        ui_print "  ++ Config file has been updated and saved to \"$PIF_DIR\"."
      else
        ui_print "  - No changes detected in \"$PIF_DIR\"."
      fi
    done

    # Handle Google apps
    # handle_google_apps

    # Show instructions only after we modified the PIF
    if [ $update_count -gt 0 ]; then
      ui_print "***************************************"
      ui_print "  ? Please disconnect your device from your Google account: https://myaccount.google.com/device-activity"
      ui_print "  ? Clean the data from Google system apps such as GMS, GSF, and Google apps."
      ui_print "  ? Then restart and make sure to reconnect to your device, Make sure if your device is logged as \"$MODEL\"."
      ui_print "  ? More info: https://t.me/PixelProps/157"
      ui_print "***************************************"
    fi
  fi
}

# TrickyStore (target.txt)
TrickyStoreTarget() {
  # Check if the directory tricky_store exists
  if [ -d "/data/adb/tricky_store" ]; then
    ui_print " - Building TrickyStore (target.txt) packages…"

    # Default TrickyStore target directory
    TARGET_DIR="/data/adb/tricky_store/target.txt"

    # Set location of target.txt to of the current working directory
    CWD_TARGET="$MODPATH"/target.txt
    shift

    # Delete old CWD target file
    [ -f "$CWD_TARGET" ] && rm -f "$CWD_TARGET"

    # Use pm list packages to get a list of installed packages
    PACKAGES=$(pm list packages | sed 's/package://g')

    # List of packages to add "!" to
    SPECIAL_PACKAGES="com.google.android.gms com.google.android.gsf com.android.vending"

    # Check if your TEE is broken
    if grep -qE "^teeBroken=(true|1)$" /data/adb/tricky_store/tee_status; then
      ui_print "  ! Hardware Attestation support not available (teeBroken=true)"
      ui_print "  ! Fallback to Broken TEE Support mode (!)"
      # If teeBroken is true or 1, add "!" after each package name
      PACKAGES=$(echo "$PACKAGES" | sed 's/$/!/g')
    else # Add "!" only to specific packages if teeBroken is false
      for pkg in $SPECIAL_PACKAGES; do
        PACKAGES=$(echo "$PACKAGES" | sed "s/^${pkg}$/${pkg}!/g")
      done
    fi

    # Save packages to MODPATH/target.txt
    echo "$PACKAGES" >"$CWD_TARGET"

    # Compares the newly generated target configuration file with existing ones and updates them if necessary.
    if [ ! -s "$CWD_TARGET" ]; then
      ui_print "  ! Built target file does not exist or is empty."
    elif [ ! -s "$TARGET_DIR" ]; then
      # Target file does not exist or is empty, so copy the new one
      cp "$CWD_TARGET" "$TARGET_DIR"
      ui_print "  ++ Target file has been created at \"$TARGET_DIR\"."
    elif ! cmp -s "$CWD_TARGET" "$TARGET_DIR"; then
      # Target file exists and is different, back up the old one and update
      mv "$TARGET_DIR" "${TARGET_DIR}.old" 2>/dev/null # 2>/dev/null suppresses the error if it does not exist
      cp "$CWD_TARGET" "$TARGET_DIR"
      ui_print "  ++ Target file has been updated and saved to \"$TARGET_DIR\"."
    else
      ui_print "  - No changes detected in \"$TARGET_DIR\"."
    fi
  fi
}

ui_print "- Building configuration file for PlayIntegrityFix & TrickyStore"

# Calling functions
PlayIntegrityFix
TrickyStoreTarget

# Done, don't close action abruptly
sleep 5 && exit 0
