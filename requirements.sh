#!/bin/bash

[[ $(type -t "print_message") != function ]] && ./util_functions.sh

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

# Install imjtool if not already installed
while [ ! -f "./imjtool" ]; do
	print_message "./imjtool not found. Installing imjtool..." info
	wget --tries=inf --show-progress -q -O "imjtool" "http://newandroidbook.com/tools/imjtool"
done
