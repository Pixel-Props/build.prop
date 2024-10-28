# Pixel Prop Builder: Streamlined OTA to Build.prop Conversion

Effortlessly extract and manage system properties from Pixel OTA updates with this robust automation suite. Designed for developers and enthusiasts alike, it simplifies the process of accessing and customizing Android build properties.

## 🚀 Quick Start & Requirements Integration

### Environment Setup & Acquisition

- Ensure a Unix-like environment with **Bash**.
- Install **core utilities**: `dos2unix`, `aria2`, `zip`, `unzip`, `p7zip`, `curl`, `jq`, and Python ^3.10.
   ```bash
   # Install python3.12
   sudo add-apt-repository ppa:deadsnakes/ppa -y
   sudo apt-get update
   sudo apt-get install python3.12 python3.12-venv python3.12-distutils
   # Install python-pip
   aria2c https://bootstrap.pypa.io/get-pip.py && python3.12 get-pip.py && rm get-pip.py
   ```

- Clone the project alongside its submodules:
    ```bash
    git clone https://github.com/Pixel-Props/build.prop --recurse
    ```

- Install payload_dumper
    ```bash
    python3.12 -m pip install payload_dumper/
    ```

1. **Obtain Pixel Images:** Download the desired factory or OTA images from [Google Android Images](https://developers.google.com/android/images) or the [Beta OTA Pages](https://developer.android.com/about/versions/15/download-ota).
2. **Effortless Extraction:**
   - Place the downloaded image files within the project's workspace.
   - Execute `./extract_images.sh` to automatically extract build properties.
3. **Stay Up-to-Date:**
   - Fetch the latest OTA images with `./download_latest_ota_build.sh <device_name1> <device_name2> ...` (e.g., `husky`, `felix_beta`, `cheetah`, `akita_beta15`).

## ✨ Key Features

- **Automated OTA Acquisition:**  Downloads the most recent builds directly from Google's official sources.
- **Seamless Image Extraction:**  Supports both factory and OTA images for versatile usage.
- **Build Prop Generation:**  Effortlessly converts extracted images into organized build.prop files.
- **GitHub Actions Integration:**
  - **Scheduled Workflows:**  Configure automated updates, builds, and releases.
    - **Duplicate Release Prevention:**  Intelligent checks prevent redundant releases.
    - **Telegram Notifications:**  Stay informed about build processes with timely updates.
- **Future Enhancements:**
  - **PlayIntegrityFix Integration:**  Planned support for enhanced app integrity checks (under development).
  - **[Pixel.Features](https://github.com/Pixel-Props/pixel.features/):**  Planned support for building Pixel-specific features (under development).

## 📝 Responsible Usage Guidelines

This project is provided for educational and experimental purposes. While designed for efficiency, it's crucial to use this tool responsibly.

- **Code Review:**  Thoroughly review and understand the code before deploying it in any environment.
- **Security Best Practices:**  Adhere to industry standards for security and legal compliance.

The creators of this project are not liable for any misuse or damages resulting from its use.

---

Ready to streamline your Android customization workflow? Dive in and unlock the power of automated build.prop extraction! Contributions are welcome to enhance the project's functionality and scope.
