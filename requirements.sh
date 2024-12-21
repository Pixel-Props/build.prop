#!/bin/bash

# Those are the only partitions we need for building properties
declare PARTITIONS2EXTRACT=("product" "vendor" "vendor_dlkm" "system" "system_ext" "system_dlkm")

[[ $(type -t "print_message") != function ]] && . ./util_functions.sh

# Install required packages and libs
install_packages "zip" "p7zip" "dos2unix" "aria2"

# Check whethever python was installed, TODO: Improve install_packages function.
if ! command -v python3 >/dev/null 2>&1; then
	install_packages "python3"
fi

# Check if python3 pip module installed
python3 -m pip -V &>/dev/null || print_message "Could not find pip module in python3, To fix this issue simply aria2c and install https://bootstrap.pypa.io/get-pip.py from python3" error

# Check if payload_dumper is available
payload_dumper -h &>/dev/null || print_message "Could not find payload_dumper executable. Install it using python3 -m pip install payload_dumper/" error

# Install imjtool if not already installed
while [ ! -f "./imjtool" ]; do
	print_message "./imjtool not found. Installing imjtool…" info
	aria2c "http://newandroidbook.com/tools/imjtool"
done
