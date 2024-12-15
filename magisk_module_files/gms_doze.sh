#!/system/bin/busybox sh

MODPATH="${0%/*}"

# If MODPATH is empty or is not default modules path, use current path
[ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/' &&
  MODPATH="$(dirname "$(readlink -f "$0")")"

# Using util_functions.sh
[ -f "$MODPATH/util_functions.sh" ] && . "$MODPATH/util_functions.sh" || abort "! util_functions.sh not found!"

###
# This feature has been disabled for now as it introduced issues with Play Services,
# Causing crashes, and resulting on not being able to update apps from Play Store.
# Ref: https://github.com/gloeyisk/universal-gms-doze/issues/62
###

# Remove setting allowing application to bypass Doze/power-save restrictions. (GMS Doze)
ALLOW_DOZE_PACKAGES="com.google.android.gms"
BLACKLISTED_CONFIGS="allow-in-power-save allow-in-data-usage-save"

ui_print "- Removing Doze/power-save bypass settings from XML files (GMS Doze)"

# Create a single grep pattern to check for any blacklisted config
grep_pattern=$(echo "$BLACKLISTED_CONFIGS" | tr ' ' '|')

find "$MODPATH" -type f -name "*.xml" -print | while IFS= read -r file; do
  for allow_doze_package in $ALLOW_DOZE_PACKAGES; do
    if grep -q "package=\"$allow_doze_package\"." "$file"; then
      if grep -Eq "$grep_pattern" "$file"; then
        # Build sed command by concatenating strings
        sed_command=""
        for config in $BLACKLISTED_CONFIGS; do
          if [ -z "$sed_command" ]; then
            sed_command="/$config/d"
          else
            sed_command="$sed_command;/$config/d"
          fi
        done

        # Use sed to remove lines with any blacklisted config in place
        sed -i -e "$sed_command" "$file"

        # Get relative path without using string indexing
        relative_path=$(echo "$file" | sed "s|^$MODPATH/||")
        if [ $? -eq 0 ]; then
          ui_print " - Successfully modified: ./$relative_path"
        else
          ui_print " - Error modifying: ./$relative_path" >&2
        fi
      fi
    fi
  done
done
