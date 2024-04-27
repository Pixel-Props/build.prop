#!/bin/bash

# Only what we need to extract
declare IMAGES2EXTRACT=("product" "vendor" "system" "system_ext")

[[ $(type -t "print_message") != function ]] && . ./util_functions.sh

# Install required packages and libs
install_packages "wget" "zip" "p7zip" "dos2unix" "aria2"
[ -x "$(command -v termux-setup-storage)" ] && install_packages "python" "python-pip" || install_packages "python3" "python3-pip"
install_pip_packages "protobuf==3.6.0"

# Make sure protobuf 3.x is installed on python3-pip
if ! pip freeze 2>/dev/null | grep "protobuf==3" &>/dev/null; then
	print_message "protobuf 3.x was not found, you can run \"pip3 install -Iv protobuf==3.6.0\" in order to install it." error
	exit
fi

# Install imjtool if not already installed
while [ ! -f "./imjtool" ]; do
	print_message "./imjtool not found. Installing imjtool…" info
	wget --tries=inf --show-progress -q -O "imjtool" "http://newandroidbook.com/tools/imjtool"
done
