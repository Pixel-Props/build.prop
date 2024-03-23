#!/system/bin/sh

# script by Chiteroman and osm0sis and x1337cn, modified by mohamedamrnady, to be compatible with pixel props
N="
";
PIF_DIRS="/data/adb/pif.json /data/adb/modules/playintegrityfix/pif.json"
PIF_MODULE_DIR="/data/adb/modules/playintegrityfix"

item() { echo "$N- $@"; }
die() { echo "$N$N! $@"; exit 1; }
file_getprop() { grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-; }

# Set ENABLE_PIF_SPOOF to false by default
ENABLE_PIF_SPOOF=false

if [[ "$ENABLE_PIF_SPOOF" = "true" ] || [[ "$PIF_PRODUCT" == *_beta ]]] && [ -d "$PIF_MODULE_DIR" ]; then
  LOCALPIF="$(readlink -f "$PWD")/pif.json";
  shift;

PROP_FILE="$MODPATH/system.prop"

[ ! -f "$PROP_FILE" ]  \
   && die "No system.prop files found in script directory";

item "Parsing system.prop(s) ...";


  _comment="https://t.me/PixelProps"
  PRODUCT=$(file_getprop "$PROP_FILE" ro.product.name);
  DEVICE=$(file_getprop "$PROP_FILE" ro.product.device);
  MANUFACTURER=$(file_getprop "$PROP_FILE" ro.product.manufacturer);
  BRAND=$(file_getprop "$PROP_FILE" ro.product.brand);
  MODEL=$(file_getprop "$PROP_FILE" ro.product.model);
  FINGERPRINT=$(file_getprop "$PROP_FILE" ro.build.fingerprint);

  [ -z "$PRODUCT" ] && PRODUCT=$(file_getprop "$PROP_FILE" ro.product.system.name);
  [ -z "$DEVICE" ] && DEVICE=$(file_getprop "$PROP_FILE" ro.product.system.device);
  [ -z "$MANUFACTURER" ] && MANUFACTURER=$(file_getprop "$PROP_FILE" ro.product.system.manufacturer);
  [ -z "$BRAND" ] && BRAND=$(file_getprop "$PROP_FILE" ro.product.system.brand);
  [ -z "$MODEL" ] && MODEL=$(file_getprop "$PROP_FILE" ro.product.system.model);
  [ -z "$FINGERPRINT" ] && FINGERPRINT=$(file_getprop "$PROP_FILE" ro.system.build.fingerprint);

if [ -z "$FINGERPRINT" ]; then
  if [ -f "$PROP_FILE" ]; then
    die "No fingerprint found, use a /system/system.prop to start";
  else
    die "No fingerprint found, unable to continue";
  fi;
fi;
echo "$FINGERPRINT";

LIST="_comment MANUFACTURER MODEL FINGERPRINT BRAND PRODUCT DEVICE";
BUILD_ID=$(file_getprop "$PROP_FILE" ro.product.build.id);
[ ! -z "$BUILD_ID" ] && LIST="$LIST BUILD_ID";

if [ "$UTC" -gt 1521158400 ] || $ALLFIELDS; then
  $ALLFIELDS || item "Build date newer than March 2018, adding SECURITY_PATCH ...";
  SECURITY_PATCH=$(file_getprop "$PROP_FILE" ro.build.version.security_patch);
  [ -z "$SECURITY_PATCH" ] && SECURITY_PATCH=$(file_getprop "$PROP_FILE" ro.build.version.security_patch);
  LIST="$LIST SECURITY_PATCH";
  $ALLFIELDS || echo "$SECURITY_PATCH";
fi;

item "Parsing build first API level ...";
  FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.product.first_api_level);
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.board.first_api_level);
  [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.board.api_level);

  if [ -z "$FIRST_API_LEVEL" ]; then
    [ ! -f vendor-"$PROP_FILE" ] && die "No first API level found, add vendor-"$PROP_FILE"";
    item "No first API level found, falling back to build SDK version ...";
    [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.build.version.sdk);
    [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.system.build.version.sdk);
    [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.build.version.sdk);
    [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.system.build.version.sdk);
    [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.vendor.build.version.sdk);
    [ -z "$FIRST_API_LEVEL" ] && FIRST_API_LEVEL=$(file_getprop "$PROP_FILE" ro.product.build.version.sdk);
  fi;
  echo "$FIRST_API_LEVEL";

  if [ "$FIRST_API_LEVEL" -gt 32 ]; then
    item "First API level 33 or higher, resetting to 32 ...";
    FIRST_API_LEVEL=32;
  fi;
  [ ! -z "$FIRST_API_LEVEL" ] && LIST="$LIST FIRST_API_LEVEL";

if [ -f "$LOCALPIF" ]; then
  item "Removing existing pif.json ...";
  rm -f "$LOCALPIF";
fi;

{
item "Writing new pif.json ...";
  echo '{' | tee -a "$LOCALPIF";
  for PROP in $LIST; do
      eval echo '\ \ \"$PROP\": \"'\$$PROP'\",';;
  done | sed '$s/,//' | tee -a "$LOCALPIF";
  echo '}' | tee -a "$LOCALPIF";

  # Kill and clear data from few Google apps
  # for google_app in $GOOGLE_APPS; do
  #   su -c am force-stop "$google_app"
  #   su -c pm clear "$google_app" # Before clearing the data we need TODO: Automate sign-out from Device Activity
  #   ui_print " ? Cleanned $google_app"
  # done
  su -c am force-stop com.google.android.gms.unstable
  echo "Killed Google Play Services!"
  for PIF_DIR in $PIF_DIRS; do
    # Compare new PIF with existing PIF file
    if echo "$(cat "$LOCALPIF")" | cmp - "$PIF_DIR" >/dev/null; then
      ui_print " - No changes detected in \"$PIF_DIR\"."
    else
      mv "$PIF_DIR" "${PIF_DIR}.old"
      cp "$LOCALPIF" "$PIF_DIR";
      ui_print " -+ PlayIntegrityFix file has been updated and saved to $PIF_DIR"
      # settings get/put --user $(am get-current-user) secure android_id
    fi
  done
  rm -f "$LOCALPIF"
}
  # Instructions
  ui_print "  ? Please disconnect your device from your Google account: https://myaccount.google.com/device-activity"
  ui_print "  ? Clean the data from Google system apps such as GMS, GSF, and Google apps."
  ui_print "  ? Then restart and make sure to reconnect to your device, Make sure if your device is logged as \"$PIF_MODEL\"."
  ui_print "  ? More info: https://t.me/PixelProps/157"
else
  ui_print " - PlayIntegritySpoof does not met device or is disabled."
fi;
