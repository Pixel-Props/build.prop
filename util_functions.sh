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

# Function to find and install packages by name using apt or pkg
install_packages() {
  local package_names=("$@")
  local package_manager=""

  if command -v apt >/dev/null 2>&1; then
    package_manager="apt"
  elif command -v pkg >/dev/null 2>&1; then
    package_manager="pkg"
  else
    print_message "Error: Neither apt nor pkg is available on this system." error
    return 1
  fi

  $package_manager update >/dev/null 2>&1

  for package in "${package_names[@]}"; do
    local is_installed
    if [ "$package_manager" = "apt" ]; then
      is_installed=$(dpkg-query -W --showformat='${Status}\n' "$package" 2>/dev/null | grep -c "install ok installed")
    elif [ "$package_manager" = "pkg" ]; then
      is_installed=$(
        pkg info "$package" >/dev/null 2>&1
        echo $?
      )
    fi

    if [ "$is_installed" -eq 0 ]; then
      print_message "Installing $package…" info
      $package_manager install -y "$package" >/dev/null 2>&1
      print_message "$package installed successfully." info
    fi
  done
}

grep_prop() {
  PROP="$1"
  shift
  FILES="$@"

  # TODO: FILES Probably need a fix?
  [ -z "$FILES" ] && FILES="/system/build.prop /system_ext/etc/build.prop /vendor/build.prop /vendor/odm/etc/build.prop /product/etc/build.prop"
  grep -m1 "^$PROP=" $FILES 2>/dev/null | cut -d= -f2- | head -n 1
}

# Function to proxy between multiple property value prefixes
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
