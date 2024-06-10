#!/bin/bash

# Only what we need to extract
declare IMAGES2EXTRACT=("product" "vendor" "system" "system_ext")

[[ $(type -t "print_message") != function ]] && . ./util_functions.sh

# Install python3.12
python3.12 -V &>/dev/null || (print_message "The payload_dumper requires python3.12, Install it manually and make sure you've got pip module. https://packaging.python.org/en/latest/tutorials/installing-packages/" error && exit)

# Check if python3.12 pip module installed
python3.12 -m pip -V &>/dev/null || (print_message "Could not find pip module in python3.12, To fix this issue simply wget and install https://bootstrap.pypa.io/get-pip.py from python3.12" error && exit)

# Check if payload_dumper is available
payload_dumperr -h &>/dev/null || (print_message "Could not find payload_dumper executable. Install it using python3.12 -m pip install payload_dumper/" error && exit)

# Install required packages and libs
install_packages "wget" "zip" "p7zip" "dos2unix" "aria2"

# Install imjtool if not already installed
while [ ! -f "./imjtool" ]; do
	print_message "./imjtool not found. Installing imjtool…" info
	wget --tries=inf --show-progress -q -O "imjtool" "http://newandroidbook.com/tools/imjtool"
done
