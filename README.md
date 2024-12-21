
# Pixel Prop Builder: Streamlined OTA to Build.prop Conversion

Effortlessly extract and manage system properties from Pixel OTA updates with this robust automation suite. Designed for developers and enthusiasts alike, it simplifies the process of accessing and customizing Android build properties.

## 🚀 Quick Start

### Prerequisites

- **Unix-like environment**: Linux or macOS with Bash.
- **Core utilities**: Ensure you have the following installed:
  - `dos2unix`
  - `aria2`
  - `zip`
  - `unzip`
  - `p7zip`
  - `curl`
- **Python ^3.8**:

    ```bash
    sudo apt-get update -y
    sudo apt-get install python3 python3-pip python3-venv -y
    ```

## Installation

1. **Clone the repository** (including submodules):

   ```bash
   git clone --recurse https://github.com/Pixel-Props/build.prop && cd build.prop
   ```

2. **Create and activate a virtual environment** (optional but recommended):

    ```bash
    python3 -m venv .venv
    . .venv/bin/activate
    ```

3. **Install dependencies**:

    ```bash
    python3 -m pip install payload_dumper --break-system-packages
    ```

## Usage

1. **Obtain Pixel Images**: Download the desired factory or OTA images from [Google Android Images](https://developers.google.com/android/images) or the [Beta OTA Pages](https://developer.android.com/about/versions/15/download-ota).
2. **Effortless Extraction**:
    - Place the downloaded image files within the project's workspace.
    - Execute `./extract_images.sh` to automatically extract build properties.
3. **Stay Up-to-Date**:
    - Fetch the latest OTA images with `./download_latest_ota_build.sh <device_name1> <device_name2> ...` (e.g., `husky`, `felix_beta`, `cheetah`, `akita_beta15`).

## ✨ Key Features

- **Automated OTA Acquisition**: Downloads the latest builds directly from Google's official sources.
- **Seamless Image Extraction**: Extracts system images from both factory images and OTA updates.
- **Build Prop Generation**: Automatically generates `build.prop` files from extracted system images.
- **Magisk Module Features**:
  - **`service.sh`**:
    - **Safe Mode**: Prevents accidental modification of critical system settings by comparing module properties with existing system values.
  - **`action.sh`**:
    - **PlayIntegrityFix**: Automatically builds the `PIF.json` configuration when using a Beta OTA. Provides options to download pre-built configurations or crawl Google's OTA pages to generate a list of devices for building the configuration.
    - **TrickyStore**: Automatically builds the target app package list and handles broken TEE status.
- **GitHub Actions Integration**:
  - **Scheduled Workflows**: Automate updates, builds, and releases on a schedule.
  - **Duplicate Release Prevention**: Prevents redundant releases with intelligent checks.
  - **Telegram Notifications**: Receive timely updates about build processes.
- **Future Enhancements**:
  - **[Pixel.Features](https://github.com/Pixel-Props/pixel.features/)**: Add support for building Pixel-specific features (currently includes `sysconfigs`).

## 📝 Responsible Usage Guidelines

This project is provided for educational and experimental purposes. While designed for efficiency, it's crucial to use this tool responsibly.

- **Code Review**: Thoroughly review and understand the code before deploying it in any environment.
- **Security Best Practices**: Adhere to industry standards for security and legal compliance.

The creators of this project are not liable for any misuse or damages resulting from its use.

----------

Ready to streamline your Android customization workflow? Dive in and unlock the power of automated build.prop extraction! Contributions are welcome to enhance the project's functionality and scope.
