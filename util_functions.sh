#!/bin/bash

print_message() {
  message="$1"
  level="$2"
  datetime="\033[1;37m$(date +'%H:%M:%S')\033[0m"

  # Change the default color based on argument log level
  case "$level" in
  error)
    message="[\033[1;31mERROR\033[0m] ($datetime) $message"
    ;;
  warning)
    message="[\033[1;33mWARNING\033[0m] ($datetime) $message"
    ;;
  info)
    message="[\033[1;32mINFO\033[0m] ($datetime) $message"
    ;;
  debug)
    message="[\033[1;36mDEBUG\033[0m] ($datetime) $message"
    ;;
  *)
    message="\033[1;37m$message\033[0m"
    ;;
  esac

  # Print the message
  echo -e "$message"

  [ "$2" = "error" ] && {
    exit 1
  }
}

# Function to install packages by name using various package managers
install_packages() {
  local package_names=("$@")

  # Determine the appropriate package manager
  local package_manager=""
  if command -v apt-get >/dev/null 2>&1; then
    package_manager="apt-get"
  elif command -v apt >/dev/null 2>&1; then
    package_manager="apt"
  elif command -v pacman >/dev/null 2>&1; then
    package_manager="pacman"
  elif command -v yum >/dev/null 2>&1; then
    package_manager="yum"
  elif command -v dnf >/dev/null 2>&1; then
    package_manager="dnf"
  elif command -v zypper >/dev/null 2>&1; then
    package_manager="zypper"
  elif command -v pkg >/dev/null 2>&1; then
    package_manager="pkg"
  else
    print_message "Error: No supported package manager found on this system." error
    return 1
  fi

  # Determine if root/sudo privileges are available
  local use_sudo=false
  if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      use_sudo=true
    else
      print_message "Error: This script requires root privileges (sudo) to install packages." error
      return 1
    fi
  fi

  # Function to execute a command with optional sudo
  run_command() {
    if $use_sudo; then
      sudo "$@"
    else
      "$@"
    fi
  }

  # Update package lists (if applicable)
  case "$package_manager" in
  apt-get | apt | yum | dnf | zypper)
    run_command $package_manager update -y >/dev/null 2>&1
    ;;
  pacman)
    run_command $package_manager -Sy >/dev/null 2>&1
    ;;
  esac

  # Install packages
  for package in "${package_names[@]}"; do
    local is_installed=1 # Assume package is NOT installed initially

    # Check if the package is already installed
    case "$package_manager" in
    apt-get | apt)
      # CORRECT: Check for "install ok installed"
      is_installed=$(dpkg-query -W --showformat='${Status}\n' "$package" 2>/dev/null | grep -c "install ok installed")
      ;;
    pacman)
      # Check the exit code, 0 means installed
      if pacman -Q "$package" >/dev/null 2>&1; then
        is_installed=0
      fi
      ;;
    yum | dnf)
      # Check the exit code, 0 means installed
      if rpm -q "$package" >/dev/null 2>&1; then
        is_installed=0
      fi
      ;;
    zypper)
      is_installed=$(zypper -q info "$package" 2>/dev/null | grep -c "Installed")
      ;;
    pkg)
      # Check the exit code, 0 means installed
      if pkg info "$package" >/dev/null 2>&1; then
        is_installed=0
      fi
      ;;
    esac

    # Install the package if it's not already installed
    if [ "$is_installed" -ne 1 ]; then
      print_message "Installing $package..." info
      case "$package_manager" in
      apt-get | apt)
        run_command $package_manager install -y "$package" >/dev/null 2>&1
        ;;
      pacman)
        run_command $package_manager -S --noconfirm "$package" >/dev/null 2>&1
        ;;
      yum | dnf)
        run_command $package_manager install -y "$package" >/dev/null 2>&1
        ;;
      zypper)
        run_command $package_manager install -y "$package" >/dev/null 2>&1
        ;;
      pkg)
        run_command $package_manager install -y "$package" >/dev/null 2>&1
        ;;
      esac
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
    print_message "\"$prop_name\" not found in \"$prop_path\"" warning
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
