#!/bin/bash

# Only what we need to extract
declare IMAGES2EXTRACT=("product" "vendor" "system" "system_ext")

[[ $(type -t "print_message") != function ]] && . ./util_functions.sh

# Make sure 7z is installed
if ! hash 7z 2>/dev/null; then
	print_message "7z was not found, you can run \"apt install p7zip-full\" in order to install it." error
	exit
fi

# Make sure dos2unix is installed
if ! hash dos2unix 2>/dev/null; then
	print_message "dos2unix was not found, you can run \"apt install dos2unix\" in order to install it." error
	exit
fi

# Make sure python3 is installed
if ! hash python3 2>/dev/null; then
	print_message "python3 was not found, you can run \"apt install python3\" in order to install it." error
	exit
fi

# Make sure python3-pip is installed
if ! hash pip3 2>/dev/null; then
	print_message "python3-pip was not found, you can run \"apt install python3-pip\" in order to install it." error
	exit
fi

# Make sure protobuf 3.x is installed on python3-pip
if ! pip freeze 2>/dev/null | grep "protobuf==3" &>/dev/null; then
	print_message "protobuf 3.x was not found, you can run \"pip3 install -Iv protobuf==3.6.0\" in order to install it." error
	exit
fi

# Install imjtool if not already installed
while [ ! -f "./imjtool" ]; do
	print_message "./imjtool not found. Installing imjtool..." info
	wget --tries=inf --show-progress -q -O "imjtool" "http://newandroidbook.com/tools/imjtool"
done
