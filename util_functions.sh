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

  # Check if apt is available
  if hash apt 2>/dev/null; then
    package_manager="apt"
  # Check if pkg is available
  elif hash pkg 2>/dev/null; then
    package_manager="pkg"
  else
    print_message "Error: Neither apt nor pkg is available on this system." error
    exit 1
  fi

  # Update package list
  $package_manager update >/dev/null 2>&1

  for package in "${package_names[@]}"; do
    # Check if the package is installed
    local is_installed
    if [ "$package_manager" = "apt" ]; then
      is_installed=$(dpkg-query -W --showformat='${Status}\n' "$package" 2>/dev/null | grep -c "install ok installed")
    elif [ "$package_manager" = "pkg" ]; then
      is_installed=$(pkg list-installed | grep -c "^$package\$" 2>/dev/null)
    fi

    # Proceed with installation or print message
    if [ "$is_installed" -eq 0 ]; then
      print_message "Installing $package..." info
      $package_manager install "$package" >/dev/null 2>&1
    fi
  done
}

# Function to find and install Python packages using pip3
install_pip_packages() {
  local pip_packages=("$@")

  # Check if python3-pip is available
  if hash pip3 2>/dev/null; then
    for package_with_version in "${pip_packages[@]}"; do
      # Extract package name and version from input
      local package=$(echo "$package_with_version" | cut -d'=' -f1)
      local version=$(echo "$package_with_version" | cut -d'=' -f3)

      # Check if the Python package is already installed using pip show
      local is_installed=$(pip3 show "$package" | grep -E "^(Name:|Version:) $package$|^Version: $version$")

      # Proceed with installation or print message
      if [ -z "$is_installed" ]; then
        print_message "Installing $package_with_version using pip3..." info
        pip3 install --ignore-installed --upgrade --force-reinstall "$package_with_version" >/dev/null 2>&1
      fi
    done
  else
    print_message "Error: pip3 is not available. You can install it by running 'apt install python3-pip'." error
    exit 1
  fi
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
