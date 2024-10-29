#!/system/bin/sh
MODPATH="${0%/*}"

# If MODPATH is empty or is not default modules path, use current path
if [ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/'; then
  MODPATH="$(dirname "$(readlink -f "$0")")"
fi

# Function to abort the script with an error message.
abort() {
  echo ""
  echo " ! $1"
  echo ""
  sleep 5
  exit 1
}

# Function to print a message to the user interface.
ui_print() { echo "$1"; }

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

# Function that normalizes a boolean value and returns 1 or 0
# Usage: boolval "value" || echo $?
boolval() {
  case "$(printf "%s" "${1:-}" | tr '[:upper:]' '[:lower:]')" in
  1 | true | on | enabled) return 1 ;;    # Truely
  0 | false | off | disabled) return 0 ;; # Falsely
  *) return 0 ;;                          # Everything else
  esac
}

# Function which checks if either it should download a file using curl or wget, then download the file
download_file() {
  url="$1"
  file="$2"

  # Check whether curl or wget is available, then download the file
  if command -v curl >/dev/null 2>&1; then
    curl -sL -o "$file" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$file" "$url"
  else
    abort " ! curl or wget not found, unable to download file"
  fi
}

# Function to handle volume key events and set variables.
volume_key_event_setval() {
  option_name=$1
  option1=$2
  option2=$3
  result_var=$4

  echo " *********************************"
  echo " *      [ VOL+ ] = [ YES ]       *"
  echo " *      [ VOL- ] = [ NO ]        *"
  echo " *      [ POWR ] = [ CANCEL ]    *"
  echo " *********************************"
  echo " * Chose your selection for \"$option_name\" !"
  echo " *********************************"

  while :; do
    keys=$(getevent -lqc1)

    if echo "$keys" | grep -q 'VOLUMEUP'; then
      echo " - Option \"$option_name\" set to \"$option1\""
      eval "$result_var='$option1'"
      return 1
    elif echo "$keys" | grep -q 'VOLUMEDOWN'; then
      echo " - Option \"$option_name\" set to \"$option2\""
      eval "$result_var='$option2'"
      return 1
    elif echo "$keys" | grep -q 'POWER'; then
      abort "Power key detected! Canceling…"
    fi
  done
}

# Function to handle volume key events and set variables from a list of options.
volume_key_event_setoption() {
  option_name=$1
  options_list=$2 # Space-separated list of options
  result_var=$3

  echo " *********************************"
  echo " *    [ VOL+ ] = [ CONFIRM ]     *"
  echo " *  [ VOL- ] = [ NEXT OPTION ]   *"
  echo " *     [ POWR ] = [ CANCEL ]     *"
  echo " *********************************"
  echo " * Choose your selection for \"$option_name\" !"
  echo " *********************************"

  # Sanitize the options list
  options_list=$(echo "$options_list" | tr -s ' ') # Ensure no extra spaces
  set -- $options_list                             # This sets the options as positional parameters ($1, $2, ..., $N)
  total_options=$#                                 # Number of options

  # If only one option is available, automatically select it
  if [ "$total_options" -eq 1 ]; then
    eval "$result_var='$1'"
    return 0
  fi

  # Display the options once
  for i in $(seq 1 $total_options); do
    eval "option=\$$i" # Get the i-th positional parameter
    ui_print " - [$i] $option"
  done

  selected_option=1

  # Display the initially selected option
  current_option=$(eval echo "\$$selected_option")
  ui_print " > $current_option"

  # Loop to capture key events and update selection
  while :; do
    # Capture key events
    keys=$(getevent -lqc1)

    if echo "$keys" | grep -q 'VOLUMEUP'; then
      # Confirm selection
      ui_print " - Option \"$option_name\" set to \"$current_option\""
      eval "$result_var='$current_option'"
      return 0 # Return success
    elif echo "$keys" | grep -q 'VOLUMEDOWN'; then
      # Move to next option
      selected_option=$((selected_option + 1))
      if [ "$selected_option" -gt "$total_options" ]; then
        selected_option=1 # Wrap around to the first option
      fi
      current_option=$(eval echo "\$$selected_option")
      ui_print " > $current_option"
    elif echo "$keys" | grep -q 'POWER'; then
      abort "Power key detected, Cancelling…"
    fi
  done
}
