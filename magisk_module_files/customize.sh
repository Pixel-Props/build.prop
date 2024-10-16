#!/system/bin/sh

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

# Module properties
MODPROP_MODEL=$(grep_prop "ro.product.vendor.model" "$MODPROP_CONTENT")
MODPROP_PRODUCT=$(grep_prop "ro.product.vendor.name" "$MODPROP_CONTENT" | tr '[:lower:]' '[:upper:]')
MODPROP_VERSION=$(grep_prop "ro.build.version.release" "$MODPROP_CONTENT")
MODPROP_SECURITYPATCH=$(grep_prop "ro.build.version.security_patch" "$MODPROP_CONTENT")
MODPROP_SDK=$(grep_prop "ro.build.version.sdk" "$MODPROP_CONTENT")
MODPROP_VERSIONCODE=$(date -d "$MODPROP_SECURITYPATCH" '+%y%m%d')
MODPROP_MONTH=$(date -d "$MODPROP_SECURITYPATCH" '+%B')
MODPROP_YEAR=$(date -d "$MODPROP_SECURITYPATCH" '+%Y')

# System properties
SYSPROP_SDK=$(grep_prop "ro.build.version.sdk" "$SYSPROP_CONTENT")

# Warn the user about potential SDK failures
if [ "$SYSPROP_SDK" -lt "$MODPROP_SDK" ]; then
    ui_print ""
    ui_print " ! YOUR SYSTEM MIGHT SOFT-BRICK !"
    ui_print " ! SYSTEM SDK: $SYSPROP_SDK !"
    ui_print " ! MODULE SDK: $MODPROP_SDK !"
    ui_print ""
fi

# Print head message
ui_print "- Installing, $MODPROP_MODEL ($MODPROP_PRODUCT) [A$MODPROP_VERSION-S$MODPROP_VERSIONCODE] - $MODPROP_MONTH $MODPROP_YEAR"

# Running the action early
[ -f "$MODPATH/action.sh" ] && . "$MODPATH"/action.sh

# Running the service early
[ -f "$MODPATH/service.sh" ] && . "$MODPATH"/service.sh

# Print footer message
ui_print "- Script by Tesla, Telegram: @T3SL4 | t.me/PixelProps"
