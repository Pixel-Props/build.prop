#!/system/bin/sh

ui_print ""
ui_print "- Building configuration file for PlayIntegrityFix"
PIF_DIR="/data/adb/pif.json"
PIF_PRODUCT=$(grep_prop "ro.product.name" "$MODPATH_SYSTEM_PROP")
PIF_DEVICE=$(grep_prop "ro.product.device" "$MODPATH_SYSTEM_PROP")
PIF_MANUFACTURER=$(grep_prop "ro.product.manufacturer" "$MODPATH_SYSTEM_PROP")
PIF_BRAND=$(grep_prop "ro.product.brand" "$MODPATH_SYSTEM_PROP")
PIF_MODEL=$(grep_prop "ro.product.model" "$MODPATH_SYSTEM_PROP")
PIF_FINGERPRINT=$(grep_prop "ro.product.build.fingerprint" "$MODPATH_SYSTEM_PROP")
PIF_SECURITY_PATCH=$(grep_prop "ro.vendor.build.security_patch" "$MODPATH_SYSTEM_PROP")
GOOGLE_APPS="com.google.android.gsf com.google.android.gms com.google.android.googlequicksearchbox"

# Grabbing SDK version from module else fallback to system default system SDK
PIF_SDK=$(grep_prop "ro.build.version.sdk" "$MODPATH_SYSTEM_PROP")
[ -z "$PIF_SDK" ] && PIF_SDK=$(grep_prop "ro.build.version.sdk")
[ -z "$PIF_SDK" ] && PIF_SDK=$(grep_prop "ro.system.build.version.sdk")
[ -z "$PIF_SDK" ] && PIF_SDK=$(grep_prop "ro.vendor.build.version.sdk")
[ -z "$PIF_SDK" ] && PIF_SDK=$(grep_prop "ro.product.build.version.sdk")

# Set ENABLE_PIF_SPOOF to false by default
ENABLE_PIF_SPOOF=false

# Check if the device name is beta or if ENABLE_PIF_SPOOF is set to true
if [[ "$PIF_PRODUCT" == *_beta ]] || [ "$ENABLE_PIF_SPOOF" = "true" ]; then

  NEW_PIF=$(
    cat <<EOF
{
  "PRODUCT": "$PIF_PRODUCT",
  "DEVICE": "$PIF_DEVICE",
  "MANUFACTURER": "$PIF_MANUFACTURER",
  "BRAND": "$PIF_BRAND",
  "MODEL": "$PIF_MODEL",
  "FINGERPRINT": "$PIF_FINGERPRINT",
  "SECURITY_PATCH": "$PIF_SECURITY_PATCH",
  "FIRST_API_LEVEL": "$PIF_SDK"
  "_comment": "https://t.me/PixelProps",
}
EOF
  )

  # Compare new PIF with existing PIF file
  if echo "$NEW_PIF" | cmp - "$PIF_DIR" >/dev/null; then
    ui_print " - No changes detected in PlayIntegrityFix file."
  else
    mv "$PIF_DIR" "${PIF_DIR}.bak"
    echo "$NEW_PIF" >"$PIF_DIR"
    ui_print " -+ PlayIntegrityFix file has been updated and saved to $PIF_DIR"

    # Kill and clear data from few Google apps
    for google_app in $GOOGLE_APPS; do
      su -c killall "$google_app"
      # su -c pm clear "$google_app" # Before clearing the data we need TODO: Automate sign-out from Device Activity
      # ui_print " ? Cleanned $google_app"
    done

    # Instructions
    ui_print "  ? Please disconnect your device from your Google account: https://myaccount.google.com/device-activity"
    ui_print "  ? Clean the data from Google system apps such as GMS, GSF, and Google apps"
    ui_print "  ? Then restart and make sure to reconnect to your device, Make sure if your device is logged as \"$PIF_MODEL\"."
    ui_print "  ? Remember to also disable any ROM internal PlayIntegrityFix spoofing e.g goolag.pif and use default module."

    # Open the guide for fixing new generation assistant and possibly more...
    nohup am start -a android.intent.action.VIEW -d https://t.me/PixelProps/157 >/dev/null 2>&1 &
  fi
else
  ui_print " - PlayIntegritySpoof does not met device or is disabled."

  # If has backup restore it
  [ -f "${PIF_DIR}.bak" ] && mv "${PIF_DIR}.bak" "$PIF_DIR"

  # If the pif.json is missing then we create one from maintained project
  if [ ! -f "$PIF_DIR" ]; then
    ui_print " -+ Missing $PIF_DIR, Downloading stable one for you."
    wget -O -q --show-progress "$PIF_DIR" "https://raw.githubusercontent.com/x1337cn/AutoPIF-Next/main/pif.json"
  fi
fi
