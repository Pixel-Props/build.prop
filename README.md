
# Pixel Prop Builder: Streamlined OTA to Build.prop Conversion

Effortlessly extract and manage system properties from Pixel OTA updates with this robust automation suite. Designed for developers and enthusiasts alike, it simplifies the process of accessing and customizing Android build properties.

## 🚀 Quick Start

### Prerequisites

- **Unix-like environment**: Linux or macOS with Bash.
- **Core utilities**:
  - `zip`, `unzip`, `p7zip-full`
  - `dos2unix`, `aria2`, `curl`
  - `e2fsprogs`, `erofs-utils`, `lz4`, `cpio`
  - `xxd`, `jq`
- **Python ≥3.8**:

    ```bash
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip python3-venv jq xxd \
      p7zip-full e2fsprogs erofs-utils lz4 cpio dos2unix aria2 curl
    ```

## Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Pixel-Props/build.prop && cd build.prop
   ```

2. **Create and activate a virtual environment** (optional but recommended):

    ```bash
    python3 -m venv .venv
    . .venv/bin/activate
    ```

3. **Install dependencies**:

    ```bash
    pip3 install payload_dumper
    ```

## Usage

### Local

1. **Fetch the latest OTA images**:

    ```bash
    ./download_latest_ota_build.sh <device_name> [device_name ...]
    ```

    Examples:
    - `./download_latest_ota_build.sh husky`
    - `./download_latest_ota_build.sh cubs grizzly_beta kodiak_beta17 yogi`

    #### Supported devices at the desired factory or OTA images from [Google Android Images](https://developers.google.com/android/images) or the [Beta OTA Pages](https://developer.android.com/about/versions/17/download-ota).

2. **Extract images and build props**:

    ```bash
    ./extract_images.sh
    ```

    This automatically:
    - Extracts payload.bin partitions one-at-a-time (low memory footprint)
    - Detects and handles **EROFS**, **ext4**, **sparse**, and **boot/init_boot** images
    - Generates `build.prop`, `system.prop`, and `module.prop`
    - Copies sysconfig XMLs

3. **Build the Magisk module**:

    ```bash
    ./build_module.sh
    ```

    The final zip is placed at the repository root (e.g. `Cubs_CD1A.260714.001.A9.zip`).

### GitHub Actions

The repository includes a fully automated CI pipeline (`.github/workflows/build.yml`):

- **Scheduled builds**: Runs every Sunday at midnight UTC.
- **Manual dispatch**: Trigger via `workflow_dispatch` with a space-separated device list or `all`.
- **Matrix builds**: Each device builds in parallel.
- **Duplicate prevention**: Skips modules already present in existing releases.
- **Aggregated releases**: All new modules are published under a single daily tag (`build-YYYYMMDD`).
- **Telegram notifications**: Sends a formatted message with clickable download links.

#### Required Secrets

| Secret | Description |
|--------|-------------|
| `TELEGRAM_BOT_TOKEN` | Your Telegram bot token from [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_CHAT_ID` | Target chat ID (user, group, or channel) |

## ✨ Key Features

- **Automated OTA Acquisition**: Downloads the latest builds directly from Google's official sources.
- **Modern Filesystem Support**: Handles EROFS, ext4, sparse images, and boot/init_boot ramdisks.
- **Build Prop Generation**: Automatically generates `build.prop`, `system.prop`, and `module.prop` from extracted system images.
- **Memory-Efficient Extraction**: Payload partitions are dumped one-at-a-time to avoid OOM on large OTAs.
- **Cross-Platform Package Management**: `requirements.sh` supports apt, pacman, dnf, yum, zypper, apk, xbps, brew, and Termux.
- **Magisk Module Features**:
  - **`service.sh`**:
    - **Safe Mode**: Prevents accidental modification of critical system settings by comparing module properties with existing system values.
    - **Integrated [Sensitive Props](https://github.com/Pixel-Props/sensitive-props) Mod Features**: Incorporates all [Sensitive Props](https://github.com/Pixel-Props/sensitive-props) Mod features and disables them if the standalone module is also present, avoiding conflicts.
    - **PIHooks (PropImitationHooks)**: A powerful internal prop spoofing system that dynamically sets essential properties based on the properties of the **module defined in `MOD_PROP_CONTENT` that is being spoofed**.
      - **Automatic PIHooks Disable**: PIHooks intelligently disables itself when it detects a properly configured Play Integrity Fix module.
      - **Selective `build.prop` Integration**: PIHooks utilizes values from your device's actual `build.prop` only when setting specific properties, like the initial SDK version, when those values are considered safe and necessary.
  - **`action.sh`**:
    - **PlayIntegrityFix**: Automatically builds the `PIF.json` configuration when using a Beta OTA. Provides options to download pre-built configurations or crawl Google's OTA pages to generate a list of devices for building the configuration.
    - **TrickyStore**: Automatically builds the target app package list and handles broken TEE status.
- **GitHub Actions Integration**:
  - **Scheduled Workflows**: Automate updates, builds, and releases on a schedule.
  - **Duplicate Release Prevention**: Prevents redundant releases by checking existing release assets.
  - **Idempotent Releases**: Re-uploads to an existing daily release tag if re-triggered.
  - **Telegram Notifications**: Receive timely updates with clickable download links.
- **Future Enhancements**:
  - **[Pixel.Features](https://github.com/Pixel-Props/pixel.features/)**: Add support for building Pixel-specific features (currently includes `sysconfigs`).

## 📝 Responsible Usage Guidelines

This project is provided for educational and experimental purposes. While designed for efficiency, it's crucial to use this tool responsibly.

- **Code Review**: Thoroughly review and understand the code before deploying it in any environment.
- **Security Best Practices**: Adhere to industry standards for security and legal compliance.

The creators of this project are not liable for any misuse or damages resulting from its use.

---

Ready to streamline your Android customization workflow? Dive in and unlock the power of automated build.prop extraction! Contributions are welcome to enhance the project's functionality and scope.
