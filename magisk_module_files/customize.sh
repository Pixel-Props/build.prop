#!/system/bin/sh

# Global variables
export MODPATH_SYSTEM_PROP="$MODPATH"/system.prop

# TODO: Import the functions below within a file e.g META-INF (update-binary) for cleaner code structure.
# Function to get a property from file
grep_prop() {
    PROP="$1"
    shift
    FILES="$@"

    [ -z "$FILES" ] && FILES="/system/build.prop /system_ext/etc/build.prop /vendor/build.prop /vendor/odm/etc/build.prop /product/etc/build.prop"
    grep -m1 "^$PROP=" $FILES 2>/dev/null | cut -d= -f2- | head -n 1
}

# Function to proxy between multiple property value prefixes
# TODO: Miss-checks some of the time FIX: (service.sh first_api_level)
get_property() {
    PROP="$1"
    shift
    FILES="$@"

    PROPERTY_PREFIXES="ro ro.board ro.system ro.vendor ro.product ro.product.product ro.product.bootimage ro.product.vendor ro.product.odm ro.product.system ro.product.system_ext ro.product.system_ext"
    for PREFIX in $PROPERTY_PREFIXES; do
        value=$(grep_prop "$PREFIX.$PROP" "$FILES")
        [ -n "$value" ] && echo "$value" && return
    done
}

# Module variables
MOD_PROP_MODEL=$(get_property model "$MODPATH_SYSTEM_PROP")
MOD_PROP_PRODUCT=$(get_property build.product "$MODPATH_SYSTEM_PROP" | tr '[:lower:]' '[:upper:]')
MOD_PROP_VERSION=$(get_property build.version.release "$MODPATH_SYSTEM_PROP")
MOD_PROP_SECURITYPATCH=$(get_property build.version.security_patch "$MODPATH_SYSTEM_PROP")
MOD_PROP_VERSIONCODE=$(date -d "$MOD_PROP_SECURITYPATCH" '+%y%m%d')
MOD_PROP_MONTH=$(date -d "$MOD_PROP_SECURITYPATCH" '+%B')
MOD_PROP_YEAR=$(date -d "$MOD_PROP_SECURITYPATCH" '+%Y')

# Print head message
ui_print "- Installing, $MOD_PROP_MODEL ($MOD_PROP_PRODUCT) Prop - $MOD_PROP_MONTH $MOD_PROP_YEAR"

# Running the PlayIntegrityFix Configuration Build Support (BETA).
[ -f "$MODPATH/pif.sh" ] && . "$MODPATH"/pif.sh

# Running the service early
[ -f "$MODPATH/service.sh" ] && . "$MODPATH"/service.sh

# Print footer message
ui_print "- Script by Tesla, Telegram: @T3SL4 | t.me/PixelProps"
