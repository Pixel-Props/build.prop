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

  if [ "$2" = "error" ]; then
    exit 1
  fi
}

# Process directories either directly or by enumerating through a specified path
#
# Args:
#   $1: SCRIPT - Script to execute for each directory (defaults to $0)
#   $2: TARGET_DIR - Optional: Specific directory to process
#   $3: SEARCH_DIR - Optional: Directory to search in (defaults to ./extracted_images)
process_directories() {
  script="${1:-$0}"
  [ -n "$2" ] && dir=$2 || {
    for dir in "${3:-./extracted_images}"/*; do
      if [ -d "$dir" ]; then
        dir=${dir%*/}
        print_message "Processing \"${dir##*/}\"…" debug

        # Execute script with directory as argument
        ./"$script" "$dir"
      fi
    done

    # Once done, exit to prevent duplicate executions
    exit 1
  }
}

# Function to install packages by name using various package managers
install_packages() {
  local package_names=("$@")
  local package_manager=""
  local pm_needs_sudo=true
  local pm_update_cmd=()
  local pm_install_cmd=()
  local pm_query_cmd=()
  local pm_query_pattern=""
  local pm_query_use_exit_code=false

  # ── Detect Termux early ──
  if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "${PREFIX:-}" == *"com.termux"* ]]; then
    if command -v pkg >/dev/null 2>&1; then
      package_manager="pkg"
      pm_needs_sudo=false
      pm_update_cmd=(pkg update)
      pm_install_cmd=(pkg install -y)
      # CRITICAL: pkg info == apt show, returns 0 for available (uninstalled) packages!
      # Termux is dpkg-based, so use dpkg-query for accurate install detection
      pm_query_cmd=(dpkg-query -W --showformat='${Status}\n')
      pm_query_pattern="install ok installed"
      pm_query_use_exit_code=false
    fi
  fi

  # ── Detect package manager (normal flow) ──
  if [[ -z "$package_manager" ]]; then
    if command -v apt-get >/dev/null 2>&1; then
      package_manager="apt-get"
      pm_update_cmd=(apt-get update -qq)
      pm_install_cmd=(apt-get install -y -qq)
      pm_query_cmd=(dpkg-query -W --showformat='${Status}\n')
      pm_query_pattern="install ok installed"
    elif command -v apt >/dev/null 2>&1; then
      package_manager="apt"
      pm_update_cmd=(apt update -qq)
      pm_install_cmd=(apt install -y -qq)
      pm_query_cmd=(dpkg-query -W --showformat='${Status}\n')
      pm_query_pattern="install ok installed"
    elif command -v pacman >/dev/null 2>&1; then
      package_manager="pacman"
      pm_update_cmd=(pacman -Sy)
      pm_install_cmd=(pacman -S --noconfirm --needed)
      pm_query_cmd=(pacman -Q)
      pm_query_use_exit_code=true
    elif command -v dnf >/dev/null 2>&1; then
      package_manager="dnf"
      pm_update_cmd=(dnf makecache -y)
      pm_install_cmd=(dnf install -y)
      pm_query_cmd=(rpm -q)
      pm_query_use_exit_code=true
    elif command -v yum >/dev/null 2>&1; then
      package_manager="yum"
      pm_update_cmd=(yum makecache -y)
      pm_install_cmd=(yum install -y)
      pm_query_cmd=(rpm -q)
      pm_query_use_exit_code=true
    elif command -v zypper >/dev/null 2>&1; then
      package_manager="zypper"
      pm_update_cmd=(zypper refresh)
      pm_install_cmd=(zypper install -y)
      pm_query_cmd=(zypper -q info)
      pm_query_pattern="^Installed.*: Yes"
    elif command -v apk >/dev/null 2>&1; then
      package_manager="apk"
      pm_needs_sudo=false
      pm_update_cmd=(apk update)
      pm_install_cmd=(apk add)
      pm_query_cmd=(apk info -e)
      pm_query_use_exit_code=true
    elif command -v xbps-install >/dev/null 2>&1; then
      package_manager="xbps"
      pm_update_cmd=(xbps-install -S)
      pm_install_cmd=(xbps-install -y)
      pm_query_cmd=(xbps-query)
      pm_query_use_exit_code=true
    elif command -v brew >/dev/null 2>&1; then
      package_manager="brew"
      pm_needs_sudo=false
      pm_update_cmd=(brew update)
      pm_install_cmd=(brew install)
      pm_query_cmd=(brew list)
      pm_query_use_exit_code=true
    elif command -v pkg >/dev/null 2>&1; then
      # FreeBSD pkg (non-Termux)
      package_manager="pkg"
      pm_update_cmd=(pkg update)
      pm_install_cmd=(pkg install -y)
      pm_query_cmd=(pkg info)
      pm_query_use_exit_code=true
    else
      print_message "Error: No supported package manager found on this system." error
      return 1
    fi
  fi

  # ── Determine sudo usage ──
  local use_sudo=false
  if $pm_needs_sudo && [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
      use_sudo=true
    else
      print_message "Error: Package installation requires root privileges (sudo not found)." error
      return 1
    fi
  fi

  run_command() {
    if $use_sudo; then
      sudo "$@"
    else
      "$@"
    fi
  }

  # ── Update package lists ──
  if [[ ${#pm_update_cmd[@]} -gt 0 ]]; then
    print_message "Updating $package_manager package lists…" debug
    if ! run_command "${pm_update_cmd[@]}" >/dev/null 2>&1; then
      print_message "Warning: Failed to update package lists (continuing anyway)…" warning
    fi
  fi

  # ── Install packages ──
  local failed=0
  for package in "${package_names[@]}"; do
    local is_installed=false

    # Check if already installed
    if $pm_query_use_exit_code; then
      if "${pm_query_cmd[@]}" "$package" >/dev/null 2>&1; then
        is_installed=true
      fi
    else
      if "${pm_query_cmd[@]}" "$package" 2>/dev/null | grep -q "$pm_query_pattern"; then
        is_installed=true
      fi
    fi

    if $is_installed; then
      print_message "$package is already installed, skipping." debug
      continue
    fi

    print_message "Installing $package via $package_manager…" info
    if run_command "${pm_install_cmd[@]}" "$package" >/dev/null 2>&1; then
      print_message "$package installed successfully." info
    else
      print_message "Failed to install $package via $package_manager." error
      ((failed++))
    fi
  done

  return $((failed > 0 ? 1 : 0))
}


# Copy files from source to destination directory based on specified patterns
#
# Args:
#   $1: SOURCE_DIR - Source directory containing files to copy
#   $2: DEST_DIR - Destination directory where files will be copied
#   $3: FILES_LIST - Space-separated list of patterns to match filenames
#
# Returns:
#   0 on success
#   1 if arguments missing, source directory not found, or destination creation fails
copy_specific_files() {
  # Check if required arguments are provided
  if [ "$#" -lt 3 ]; then
    print_message "Usage: copy_specific_files SOURCE_DIR DEST_DIR FILES_LIST" info
    print_message "Example: copy_specific_files /src /dest 'file1.xml file2.xml pattern3'" debug
    return 1
  fi

  # Parse arguments
  src_dir="$1"
  dest_dir="$2"
  files_list="$3"

  # Check if source directory exists
  if [ ! -d "$src_dir" ]; then
    print_message "Source directory '$src_dir' does not exist" error
    return 1
  fi

  # Create destination directory
  mkdir -p "$dest_dir" || {
    print_message "Failed to create destination directory '$dest_dir'" error
    return 1
  }

  # Counter for copied files
  copied=0

  # Process each file in source directory
  for file in "$src_dir"/*; do
    [ -f "$file" ] || continue # Skip if not a regular file

    # Get basename of file
    filename="${file##*/}"

    # Check against each pattern
    for pattern in $files_list; do
      if echo "$filename" | grep -q "$pattern"; then
        if cp "$file" "$dest_dir/"; then
          copied=$((copied + 1))
        else
          print_message "Failed to copy: \"$filename\"" warning
        fi
        break
      fi
    done
  done

  # Report results
  print_message "Copied $copied files to \"$dest_dir\"" debug
  return 0
}

# Function to find build & system properties within a specified directory.
find_prop_files() {
  dir="$1"
  prop_files=()

  while IFS= read -r -d '' file; do
    if [[ "$file" == */build.prop || "$file" == */system.prop ]]; then
      prop_files+=("${file}")
    fi
  done < <(find "$dir" -type f -print0)

  echo "${prop_files[@]}"
}

# Function to grep a property value from a list of files
grep_prop() {
  PROP="$1"
  shift
  FILES_or_VAR="$@"

  # if it's a file, use grep normally
  # else just echo the content from a variable.
  if [[ -f "$FILES_or_VAR" ]]; then
    grep -m1 "^$PROP=" "$FILES_or_VAR" 2>/dev/null | cut -d= -f2- | head -n 1
  else
    grep -m1 "^$PROP=" <<< "$FILES_or_VAR" 2>/dev/null | cut -d= -f2- | head -n 1
  fi
}

# Function to proxy between multiple property value prefixes
get_property() {
  PROP="$1"
  shift
  FILES="$@"

  PROPERTY_PREFIXES="ro ro.board ro.system ro.vendor ro.product ro.product.product ro.product.bootimage ro.product.vendor ro.product.odm ro.product.system ro.product.system_ext ro.product.system_ext"
  for PREFIX in $PROPERTY_PREFIXES; do
    name="$PREFIX.$PROP"
    value=$(grep_prop "$name" "$FILES")

    # If we find a value we suppose that we know both name and value.
    [ -n "$value" ] && echo "$name=$value" && return
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
    print_message "No property name provided for $2" error
    return 1
  fi

  if [ -z "$3" ]; then
    print_message "No property value provided for $2, skipping…" warning
    return 0
  fi

  "$1" "$2=$3"
}

build_system_prop() {
  prop_name="$1"
  prop_value=$(grep_prop "$prop_name" "$EXT_PROP_CONTENT")

  if [ -z "$prop_value" ]; then
    print_message "\"$prop_name\" not found" warning
    return 1
  fi

  add_prop_as_ini "to_system_prop" "$prop_name" "$prop_value"
}

extract_ext4() {
  local img="$1"
  local dest="$2"

  print_message "Extracting ext4 image via 7z…" debug
  mkdir -p "$dest"
  # 7z reads ext4 fine; single-thread to keep RAM low
  7z x "$img" -o"$dest" -y -mmt1 &>/dev/null
}

extract_erofs() {
  local img="$1"
  local dest="$2"

  if ! command -v fsck.erofs >/dev/null 2>&1; then
    print_message "fsck.erofs not found. Install erofs-utils." warning
    return 1
  fi

  print_message "Extracting EROFS image via fsck.erofs…" debug
  
  # --force allows extracting to existing/non-empty directories
  if ! fsck.erofs --extract="$dest" --force "$img" &>/dev/null; then
    print_message "Failed to extract EROFS image ${img##*/}, skipping…" warning
    return 1
  fi
}

extract_android_boot() {
  local img="$1"
  local dest="$2"

  local boot_out="$dest/.boot_tmp_$$"
  mkdir -p "$boot_out"

  if ! python3 ./unpack_bootimg.py --boot_img "$img" --out "$boot_out" >/dev/null 2>&1; then
    rm -rf "$boot_out"
    return 1
  fi

  if [ ! -f "$boot_out/ramdisk" ]; then
    rm -rf "$boot_out"
    return 1
  fi

  mkdir -p "$boot_out/rd"
  local compr
  compr=$(file -b "$boot_out/ramdisk" | awk '{print tolower($1)}')

  case "$compr" in
    lz4)
      lz4 -d "$boot_out/ramdisk" - | (cd "$boot_out/rd" && cpio -idmv 2>/dev/null)
      ;;
    gzip)
      gunzip -c "$boot_out/ramdisk" | (cd "$boot_out/rd" && cpio -idmv 2>/dev/null)
      ;;
    *)
      (cd "$boot_out/rd" && cpio -idmv 2>/dev/null) < "$boot_out/ramdisk"
      ;;
  esac

  find "$boot_out/rd" -name "build.prop" | while read -r f; do
    local rel="${f#$boot_out/rd}"
    mkdir -p "$dest$(dirname "$rel")"
    cp "$f" "$dest$rel"
  done

  rm -rf "$boot_out"
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

  local img_path="$1/$2.img"
  local dest_dir="$1/extracted/$2"

  [ ! -f "$img_path" ] && return 0

  print_message "Extracting \"${1##*/}/$2.img\"" debug
  mkdir -p "$dest_dir"

  # ── Step 1: Handle sparse images ──
  local work_img="$img_path"
  local raw_img=""

  local magic
  magic=$(xxd -l 4 -p "$img_path" 2>/dev/null || echo "")
  if [ "$magic" = "3aff26ed" ] || file -b "$img_path" 2>/dev/null | grep -qi "sparse"; then
    if command -v simg2img >/dev/null 2>&1; then
      raw_img="$1/$2.raw"
      print_message "Converting sparse image to raw…" debug
      if simg2img "$img_path" "$raw_img" 2>/dev/null; then
        work_img="$raw_img"
      else
        print_message "simg2img failed, working with image as-is…" warning
        raw_img=""
      fi
    else
      print_message "simg2img not found, cannot convert sparse image." warning
    fi
  fi

  # ── Step 2: Detect image type and extract ──
  local fs_type
  fs_type=$(file -b "$work_img" 2>/dev/null | head -1 | awk '{print tolower($1)}')

  case "$fs_type" in
    erofs)
      extract_erofs "$work_img" "$dest_dir" || true
      ;;
    ext*|"linux")
      extract_ext4 "$work_img" "$dest_dir" || true
      ;;
    android)
      extract_android_boot "$work_img" "$dest_dir" || true
      ;;
    *)
      print_message "Unknown filesystem ($fs_type), trying 7z fallback…" warning
      7z x "$work_img" -o"$dest_dir" -y -mmt1 &>/dev/null || true
      ;;
  esac

  # Cleanup
  [ -n "$raw_img" ] && rm -f "$raw_img"
  rm -f "$img_path"
}

# Using requirements.sh
# [ -f "requirements.sh" ] && . ./requirements.sh || { echo "requirements.sh not found" && exit 1; }
