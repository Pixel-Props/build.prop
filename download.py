import os
import sys
import requests
import re
from pathlib import Path

# Helper function to print messages
def print_message(message, level="info"):
    levels = {
        "info": "\033[94m[INFO]\033[0m",
        "error": "\033[91m[ERROR]\033[0m",
        "debug": "\033[92m[DEBUG]\033[0m"
    }
    print(f"{levels.get(level, '[INFO]')} {message}")

# Check if device names are provided
if len(sys.argv) < 2:
    print_message("No OTA device name provided", "error")
    sys.exit(1)

device_names = sys.argv[1:]
print_message(f"Downloading OTA builds for the following devices: {', '.join(device_names)}", "info")

# Make sure download directory exists
download_dir = Path("./dl")
download_dir.mkdir(exist_ok=True)

# Function to get the last build URL
def get_last_build_url(device_name, android_version):
    if "_beta" in device_name:
        url = f"https://developer.android.com/about/versions/{android_version}/download-ota"
        regex = rf"https://\S+{device_name}\S+\.zip"
    else:
        url = 'https://developers.google.com/android/ota'
        regex = rf"https://\S+{device_name}\S+\.zip"

    print_message(f"Fetching URL: {url}", "debug")
    response = requests.get(url, cookies={"devsite_wall_acks": "nexus-ota-tos"})
    
    if response.status_code != 200:
        print_message(f"Failed to fetch URL {url} with status code {response.status_code}", "error")
        return None

    urls = re.findall(regex, response.text)
    if urls:
        return urls[-1]

    print_message(f"No URLs found for {device_name} using regex {regex}", "error")
    return None

# Function to download a file
def download_file(url, dest_folder):
    local_filename = os.path.join(dest_folder, url.split('/')[-1])
    print_message(f"Downloading {url} to {local_filename}", "debug")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(local_filename, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
    print_message(f"Downloaded {url} to {local_filename}", "info")
    return local_filename

# # Loop over each device name
for device_name in device_names:
    android_version = re.search(r'\d+', device_name)
    android_version = int(android_version.group()) if android_version and 14 <= int(android_version.group()) <= 15 else 14

    # Remove any numbers from the device name
    device_name = re.sub(r'\d+', '', device_name)

    last_build_url = get_last_build_url(device_name, android_version)

    if last_build_url:
        print_message(f"Downloading OTA build for {device_name.capitalize()} (\"{last_build_url}\")…", "debug")
        download_file(last_build_url, download_dir)
    else:
        print_message(f"No OTA build found for {device_name}", "error")

print_message("Download complete", "info")
sys.exit(0)
