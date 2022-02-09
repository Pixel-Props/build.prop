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
if [ ! -f "./imjtool" ]; then
	print_message "./imjtool not found. Installing imjtool..." info
	wget -O - http://newandroidbook.com/tools/imjtool.tgz &>/dev/null | tar xz imjtool.ELF64 &>/dev/null
	mv imjtool.ELF64 imjtool
fi
