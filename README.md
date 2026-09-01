# Build Prop BETA Builder

Automated toolchain to fetch, extract, and build Magisk/KernelSU/APatch modules containing system properties from Google Pixel Beta and QPR OTA images.

## Architecture & Pipeline

```
[OTA Acquisition] -> [Image Extraction] -> [Property Synthesis] -> [Module Packaging] -> [CI & Release]
```

### 1. OTA Acquisition (`download_latest_ota_build.sh`)
- Target argument resolution:
  - Standard builds: `<codename>` (queries `developers.google.com/android/ota`)
  - Beta main builds: `<codename>_beta<version>` (queries `developer.android.com/about/versions/<version>/download-ota`)
  - Beta QPR builds: `<codename>_beta<version>q<qpr>` (queries `developer.android.com/about/versions/<version>/qpr<qpr>/download-ota`)
- Queries Google Developer endpoints with required session cookies.
- Parallel download engine using `aria2c` with multi-connection chunks into `./dl/`.

### 2. Image Extraction (`extract_images.sh`, `util_functions.sh`)
- Processes payload archives (`payload.bin` from OTA zip or raw factory zip).
- Target partitions: `product`, `vendor`, `vendor_dlkm`, `system`, `system_ext`, `system_dlkm`, `init_boot`.
- Single-partition streaming extraction via `payload_dumper` to prevent out-of-memory errors on large updates.
- Filesystem detection and unpacking:
  - **EROFS**: extracted via `fsck.erofs --extract`
  - **ext4**: extracted via `7z` (single-threaded mode)
  - **Android Sparse**: decompressed to raw image via `simg2img` prior to extraction
  - **Boot / Ramdisk (`init_boot`, `boot`)**: unpacked via `unpack_bootimg.py`, decompressed using `lz4`, `gzip`, or `cpio`
- Traverses extracted partitions to locate all `build.prop` files.

### 3. Property Synthesis (`build_props.sh`, `build_sysconfig.sh`)
- Parses property keys from extracted files and builds target outputs:
  - `system.prop`: spoofed fingerprints, build IDs, incremental versions, security patch levels, and UUID properties across all partitions.
  - `system/etc/ramdisk/build.prop`: dedicated bootimage properties extracted from ramdisk.
  - `module.prop`: Magisk module metadata with dynamic versioning and naming.
- Fallback attestation logic: checks `product.*` and `system.*` properties if `vendor.*` values are missing.
- Sysconfig XML extraction: copies Pixel experience XMLs (`pixel_experience_*.xml`, `google.xml`, `adaptivecharging.xml`, `quick_tap.xml`, etc.) into `system/product/etc/sysconfig/`.

### 4. Module Packaging (`build_module.sh`)
- Assembles properties, extracted sysconfig files, and template scripts (`module_files/`) into `result/<Codename>_<BuildID>/`.
- Includes runtime module scripts:
  - `service.sh`: boot-time property application with safe mode and TrickyStore integration.
  - `post-fs-data.sh`: early boot property overrides.
  - `customize.sh`: Magisk / KernelSU / APatch installation logic.
  - `webroot/`: WebUI dashboard support.
- Generates SHA256 integrity checksums for all executable shell scripts.
- Compresses the directory into a flashable module zip at repository root (`<Codename>_<BuildID>.zip`).

### 5. Continuous Integration (`.github/workflows/build.yml`)
- **3-Stage Workflow**:
  1. `prepare`: Generates dynamic matrix JSON from dispatch inputs or default beta device list.
  2. `build`: Matrix parallel job per device (downloads, extracts, builds, and verifies SHA256/duplicate status).
  3. `release`: Aggregates built modules, creates/updates GitHub Release, and notifies Telegram.
- **Trigger**:
  - Scheduled: Runs monthly on the 28th at 00:00 UTC.
  - Manual (`workflow_dispatch`): Custom device names (space-separated or `all`) with optional pre-release flag.
- **Tag Conventions**:
  - Standard / Scheduled runs: `beta-YYYYMMDD` (Release)
  - Pre-release manual runs: `alpha-YYYYMMDD` (Pre-Release)
- **Duplicate Prevention**: Queries existing release assets via GitHub CLI (`gh`) to skip rebuilding existing versions.
- **Telegram Notifications**: Sends release summaries with direct asset download links and formatted device lists.

---

## Directory Structure

```
.
├── .github/workflows/
│   └── build.yml               # 3-stage CI/CD pipeline
├── module_files/               # Template files included in the Magisk module
│   ├── customize.sh
│   ├── service.sh
│   ├── post-fs-data.sh
│   ├── gms_doze.sh
│   └── webroot/
├── download_latest_ota_build.sh # OTA fetcher
├── extract_images.sh           # Main extraction orchestrator
├── build_props.sh              # Property generator
├── build_sysconfig.sh          # Sysconfig XML parser
├── build_module.sh             # Magisk zip packager
├── requirements.sh             # Runtime dependency checker
└── util_functions.sh           # Core extraction & utility library
```

---

## Prerequisites

- **Environment**: Linux (Debian, Ubuntu, Arch, Fedora, Alpine) or macOS
- **System Binaries**: `bash`, `coreutils`, `p7zip`, `erofs-utils`, `lz4`, `cpio`, `dos2unix`, `aria2`, `curl`, `xxd`, `jq`
- **Python**: Python 3.8+ with `payload_dumper`

### Dependency Installation

Debian / Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y p7zip-full e2fsprogs erofs-utils lz4 cpio \
  dos2unix aria2 curl xxd python3 python3-pip jq
pip3 install payload_dumper
```

Arch Linux:
```bash
sudo pacman -S --needed p7zip erofs-utils lz4 cpio dos2unix aria2 curl xxd jq python python-pip
pip install payload_dumper
```

Fedora:
```bash
sudo dnf install -y p7zip p7zip-plugins erofs-utils lz4 cpio dos2unix aria2 curl python3 python3-pip jq
pip3 install payload_dumper
```

## Installation & Setup

1. Clone the repository with submodules:
```bash
git clone --recurse-submodules https://github.com/Elcapitanoe/Build-Prop-BETA.git
cd Build-Prop-BETA
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

---

## Local Usage

### Step 1: Download OTA Images
Pass one or more device identifiers:
```bash
# Standard Beta
./download_latest_ota_build.sh husky_beta17

# Specific QPR Beta
./download_latest_ota_build.sh felix_beta17q2 tokay_beta17q2

# Multiple targets
./download_latest_ota_build.sh marlin stallion_beta17q2 rango_beta17q2
```

### Step 2: Extract & Build Modules
```bash
./extract_images.sh
```
This triggers image extraction, property resolution (`build_props.sh`), sysconfig extraction (`build_sysconfig.sh`), and zip packaging (`build_module.sh`).

Output module zips are placed at the repository root:
```
./Felix_UP2A.260805.003.zip
```

---

## GitHub Actions Secrets

Configure these repository secrets in GitHub (`Settings -> Secrets and variables -> Actions`):

| Secret | Description |
|---|---|
| `GITHUB_TOKEN` | Automatically provided by GitHub Actions (requires `contents: write`) |
| `TELEGRAM_BOT_TOKEN` | Bot API token from `@BotFather` |
| `TELEGRAM_CHAT_ID` | Telegram chat, channel, or group ID for release notifications |
