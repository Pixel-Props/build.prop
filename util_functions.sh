#!/bin/bash

print_message() {
  default_color="\033[0m"

  # Change the default color based on argument log level
  if [ "$2" = "error" ]; then
    default_color="\033[0;31m"
  elif [ "$2" = "warning" ]; then
    default_color="\033[0;33m"
  elif [ "$2" = "info" ]; then
    default_color="\033[0;32m"
  elif [ "$2" = "debug" ]; then
    default_color="\033[0;36m"
  fi

  # Print the message
  echo -e "${default_color}$1\033[0m"
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  cat $FILES 2>/dev/null | dos2unix | sed -n "$REGEX" | head -n 1
}

to_system_prop() {
  if [ -z "$1" ]; then
    print_message "No string to add provided" error
    return 1
  fi

  system_prop="$system_prop$1
"
}

to_module_prop() {
  if [ -z "$1" ]; then
    print_message "No string to add provided" error
    return 1
  fi

  module_prop="$module_prop$1
"
}

add_prop_as_ini() {
  if [ -z "$1" ] || [[ $(type -t "$1") != function ]]; then
    print_message "Invalid function name provided for building props" error
    return 1
  fi

  if [ -z "$2" ]; then
    print_message "No property name provided" error
    return 1
  fi

  if [ -z "$3" ]; then
    print_message "No property value provided" error
    return 1
  fi

  "$1" "$2=$3"
}

build_prop() {
  if [ -z "$1" ] || [[ $(type -t "$1") != function ]]; then
    print_message "Invalid function name provided for building props" error
    return 1
  fi

  # make sure file exist
  if [ ! -f "$2" ]; then
    print_message "File $2 does not exist" error
    return 1
  fi
  if [ -z "$2" ] || [ ! -f "$2" ]; then
    print_message "Please provide a valid prop path file" error
    return 1
  fi

  if [ -z "$3" ]; then
    print_message "No property name provided" error
    return 1
  fi

  local prop_path="$2"
  local prop_name="$3"
  local prop_value=$(grep_prop "$prop_name" "$prop_path")

  if [ -z "$prop_value" ]; then
    print_message "\"$prop_name\" not found in \"$prop_path\"" error
    return 1
  fi

  add_prop_as_ini to_system_prop "$prop_name" "$prop_value"
}

extract_image() {
  if [ -z "$1" ]; then
    print_message "No directory destination provided" error
    return 1
  fi

  if [ -z "$2" ]; then
    print_message "No image name provided" error
    return 1
  fi

  if [ -f "$1/$2.img" ]; then
    print_message "Extracting \"${1##*/}/$2.img\"" debug

    7z x "$1/$2.img" -o"$1/extracted/$2" -y &>/dev/null
    # ImjTool not required since of A13?
    # ./imjtool "$1/$2.img" extract &>/dev/null
    # rm -rf extracted
  fi
}

# Using requirements.sh
[ -f "requirements.sh" ] && . ./requirements.sh || { echo "requirements.sh not found" && exit 1; }
