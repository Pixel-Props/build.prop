#!/system/bin/busybox sh
MODPATH="${0%/*}"

# If MODPATH is empty or is not default modules path, use current path
[ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/' &&
  MODPATH="$(dirname "$(readlink -f "$0")")"

# Function that normalizes a boolean value and returns 0, 1, or a string
# Usage: boolval "value"
boolval() {
  case "$(printf "%s" "${1:-}" | tr '[:upper:]' '[:lower:]')" in
  1 | true | on | enabled) return 0 ;;    # Truely
  0 | false | off | disabled) return 1 ;; # Falsely
  *) return 1 ;;                          # Everything else - return a string
  esac
}

# Enhanced boolval function to only identify booleans
is_bool() {
  case "$(printf "%s" "${1:-}" | tr '[:upper:]' '[:lower:]')" in
  1 | true | on | enabled | 0 | false | off | disabled) return 0 ;; # True (is a boolean)
  *) return 1 ;;                                                    # False (not a boolean)
  esac
}

# Function to print a message to the user interface.
ui_print() { echo "$1"; }

# Function to abort the script with an error message.
abort() {
  message="$1"
  remove_module="${2:-true}"

  ui_print " [!] $message"

  # Remove module on next reboot if requested
  if boolval "$remove_module"; then
    touch "$MODPATH/remove"
    ui_print " ! The module will be removed on next reboot !"
    ui_print ""
    sleep 5
    exit 1
  fi

  sleep 5
  return 1
}

# Function to find all .prop files within a specified directory
find_prop_files() {
  dir="$1"
  maxdepth="$2"
  maxdepth=${maxdepth:-3}

  find "$dir" -maxdepth "$maxdepth" -type f -name '*.prop' -print 2>/dev/null
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

set_permissions() { # Handle permissions without errors
  [ -e "$1" ] && chmod "$2" "$1" &>/dev/null
}

# Function to construct arguments for resetprop based on prop name
_build_resetprop_args() {
  prop_name="$1"
  shift

  case "$prop_name" in
  persist.*) set -- -p -v "$prop_name" ;; # Use persist mode
  *) set -- -n -v "$prop_name" ;;         # Use normal mode
  esac
  echo "$@"
}

exist_resetprop() { # Reset a property if it exists
  getprop "$1" | grep -q '.' && resetprop $(_build_resetprop_args "$1") ""
}

check_resetprop() { # Reset a property if it exists and doesn't match the desired value
  VALUE="$(resetprop -v "$1")"
  [ -n "$VALUE" ] && [ "$VALUE" != "$2" ] && resetprop $(_build_resetprop_args "$1") "$2"
}

maybe_resetprop() { # Reset a property if it exists and matches a pattern
  VALUE="$(resetprop -v "$1")"
  [ -n "$VALUE" ] && echo "$VALUE" | grep -q "$2" && resetprop $(_build_resetprop_args "$1") "$3"
}

replace_value_resetprop() { # Replace a substring in a property's value
  VALUE="$(resetprop -v "$1")"
  [ -z "$VALUE" ] && return
  VALUE_NEW="$(echo -n "$VALUE" | sed "s|${2}|${3}|g")"
  [ "$VALUE" == "$VALUE_NEW" ] || resetprop $(_build_resetprop_args "$1") "$VALUE_NEW"
}

# This function aims to delete or obfuscate specific strings within Android system properties,
# by replacing them with random hexadecimal values which should match with the original string length.
hexpatch_deleteprop() {
  # Path to magiskboot (determine it once, at the beginning)
  magiskboot_path=$(which magiskboot 2>/dev/null || find /data/adb /data/data/me.bmax.apatch/patch/ -name magiskboot -print -quit 2>/dev/null)
  [ -z "$magiskboot_path" ] && abort "magiskboot not found" false

  # Loop through all arguments passed to the function
  for search_string in "$@"; do
    # Hex representation in uppercase
    search_hex=$(echo -n "$search_string" | xxd -p | tr '[:lower:]' '[:upper:]')

    # Generate a random LOWERCASE alphanumeric string of the required length, using only 0-9 and a-f
    replacement_string=$(cat /dev/urandom | tr -dc '0-9a-f' | head -c ${#search_string})

    # Convert the replacement string to hex and ensure it's in uppercase
    replacement_hex=$(echo -n "$replacement_string" | xxd -p | tr '[:lower:]' '[:upper:]')

    # Get property list from search string
    # Then get a list of property file names using resetprop -Z and pipe it to find
    getprop | cut -d'[' -f2 | cut -d']' -f1 | grep "$search_string" | while read prop_name; do
      resetprop -Z "$prop_name" | cut -d' ' -f2 | cut -d':' -f3 | while read -r prop_file_name_base; do
        # Use find to locate the actual property file (potentially in a subdirectory)
        # and iterate directly over the found paths
        find /dev/__properties__/ -name "*$prop_file_name_base*" | while read -r prop_file; do
          # echo "Patching $prop_file: $search_hex -> $replacement_hex"
          "$magiskboot_path" hexpatch "$prop_file" "$search_hex" "$replacement_hex" >/dev/null 2>&1

          # Check if the patch was successfully applied
          if [ $? -eq 0 ]; then
            echo " ? Successfully patched $prop_file (replaced part of '$search_string' with '$replacement_string')"
          # else
          #   echo " ! Failed to patch $prop_file (replacing part of '$search_string')."
          fi
        done
      done

      # Unset the property after patching to ensure the change takes effect
      resetprop -n --delete "$prop_name"
      ret=$?

      if [ $ret -eq 0 ]; then
        echo " ? Successfully unset $prop_name"
      else
        echo " ! Failed to unset $prop_name"
      fi
    done
  done
}

# Function to download a file using curl or wget with retry mechanism
download_file() {
  url="$1"
  file="$2"
  retries=5

  # Try download with either curl or wget
  while [ $retries -gt 0 ]; do
    if command -v curl >/dev/null 2>&1; then
      if curl -sL --connect-timeout 10 -o "$file" "$url"; then
        return 0
      fi
    elif command -v wget >/dev/null 2>&1; then
      if wget -qO "$file" "$url" --timeout=10; then
        return 0
      fi
    else
      abort " ! curl or wget not found, unable to download file"
    fi

    retries=$((retries - 1))
    [ $retries -gt 0 ] && sleep 5
  done

  # If we get here, all attempts failed
  rm -f "$file"
  abort " ! Download failed after $retries attempts"
}

# Function to handle volume key events and set variables.
volume_key_event_setval() {
  if [ $# -ne 4 ]; then
    abort "Error: volume_key_event_setval() expects 4 arguments: option_name, option1, option2, result_var"
  fi

  option_name="$1"
  option1="$2"
  option2="$3"
  result_var="$4"

  # POSIX-compliant check for valid variable name
  case "$result_var" in
  '' | *[!_a-zA-Z]* | *[!_a-zA-Z0-9]*)
    abort "Error: Invalid variable name provided: \"$result_var\""
    ;;
  esac

  key_yes="${KEY_YES:-VOLUMEUP}"
  key_no="${KEY_NO:-VOLUMEDOWN}"
  key_cancel="${KEY_CANCEL:-POWER}"
  ui_print " *********************************"
  ui_print " *      [ VOL+ ] = [ YES ]       *"
  ui_print " *      [ VOL- ] = [ NO ]        *"
  ui_print " *      [ POWR ] = [ CANCEL ]    *"
  ui_print " *********************************"
  ui_print " * Choose your value for \"$option_name\""
  ui_print " *********************************"

  while :; do
    key=$(getevent -lqc1 | grep -oE "$key_yes|$key_no|$key_cancel")
    ret=$?

    # Check if getevent succeeded
    if [ -z "$key" ] && [ $ret -ne 0 ]; then
      ui_print " ! Warning: getevent command failed. Retrying…" >&2
      sleep 1
      continue
    fi

    case "$key" in
    "$key_yes")
      ui_print " - Option \"$option_name\" set to \"$option1\""
      ui_print " *********************************"
      eval "$result_var='$option1'"
      sleep 0.5
      return 0
      ;;
    "$key_no")
      ui_print " - Option \"$option_name\" set to \"$option2\""
      ui_print " *********************************"
      eval "$result_var='$option2'"
      sleep 0.5
      return 0
      ;;
    "$key_cancel")
      abort "Cancel key detected! Canceling…" true
      ;;
    esac
  done
}

# Function to handle volume key events and set variables from a list of options.
volume_key_event_setoption() {
  option_name="$1"
  options_list=$2 # Space-separated list of options
  result_var="$3"

  # Check for valid variable name
  case "$result_var" in
  '' | *[!_a-zA-Z]* | *[!_a-zA-Z0-9]*)
    abort "Error: Invalid variable name provided: \"$result_var\""
    ;;
  esac

  # Shift to remove the first three arguments (option_name, options_list, result_var)
  shift 1

  # Sanitize the options list (ensure no extra spaces)
  options_list=$(echo "$options_list" | tr -s ' ')

  # Store the original positional parameters in a temporary variable
  original_options="$*"

  # Convert options list to an array (using positional parameters)
  set -- $(echo "$options_list")
  total_options=$#

  # If only one option, select it
  if [ "$total_options" -eq 1 ]; then
    eval "$result_var='$1'"
    return 0
  fi

  key_yes="${KEY_YES:-VOLUMEUP}"
  key_no="${KEY_NO:-VOLUMEDOWN}"
  key_cancel="${KEY_CANCEL:-POWER}"
  ui_print " *********************************"
  ui_print " *    [ VOL+ ] = [ CONFIRM ]     *"
  ui_print " *  [ VOL- ] = [ NEXT OPTION ]   *"
  ui_print " *     [ POWR ] = [ CANCEL ]     *"
  ui_print " *********************************"
  ui_print " * Choose your value for \"$option_name\" !"
  ui_print " *********************************"

  # Display the options once
  # i=1
  # while [ $# -gt 0 ]; do
  #   option="$1"
  #   ui_print " - [$i] $option"
  #   shift
  #   i=$((i + 1))
  # done

  selected_option=1

  # Restore the original positional parameters
  set -- $original_options

  # Display the initially selected option
  eval "current_option=\$${selected_option}"
  ui_print " > $current_option"

  while :; do
    key=$(getevent -lqc1 | grep -oE "$key_yes|$key_no|$key_cancel")
    ret=$?

    # Check if getevent succeeded
    if [ -z "$key" ] && [ $ret -ne 0 ]; then
      ui_print " ! Warning: getevent command failed. Retrying…" >&2
      sleep 1
      continue
    fi

    case "$key" in
    "$key_yes")
      ui_print " - Option \"$option_name\" set to \"$current_option\""
      ui_print " *********************************"
      eval "$result_var='$current_option'"
      sleep 1
      return 0 # Return success
      ;;
    "$key_no")
      selected_option=$((selected_option + 1))
      if [ "$selected_option" -gt "$total_options" ]; then
        selected_option=1
      fi

      # Use shift to get the selected option
      set -- $original_options # Reset positional parameters
      i=1
      while [ $i -lt $selected_option ]; do
        shift
        i=$((i + 1))
      done
      current_option="$1"
      ui_print " > $current_option"
      ;;
    "$key_cancel")
      abort "Cancel key detected, Cancelling…" true
      ;;
    esac

    # Wait some time before checking again
    sleep 0.5
  done
}
