# PrismGB Raspberry Pi Deployment Guide

## Overview

PrismGB can be deployed to Raspberry Pi in two ways:

1. **Source Package** (Recommended) - Build on the Pi itself
2. **Pre-built Binaries** - If ARM builds become available

## Method 1: Source Package (Recommended)

This method packages the entire codebase and builds it on the target Pi, avoiding cross-compilation issues.

### Creating the Source Package

On your development machine (Mac/Linux/Windows):

```bash
# Create source package
npm run package:rpi-source

# This creates: raspberry-pi/prismgb-source-{version}.tar.gz
```

### Deploying to Raspberry Pi

1. **Copy the source package to your Pi:**
   ```bash
   # Via SCP
   scp raspberry-pi/prismgb-source-*.tar.gz pi@raspberrypi.local:~
   
   # Or via USB drive, etc.
   ```

2. **On the Raspberry Pi, extract and build:**
   ```bash
   tar -xzf prismgb-source-*.tar.gz
   cd prismgb-source-*
   chmod +x build-on-pi.sh
   ./build-on-pi.sh
   ```

3. **Set up kiosk mode:**
   ```bash
   cd raspberry-pi
   chmod +x setup.sh
   ./setup.sh
   ```

### What Happens During Build

The build process on the Pi:
1. Installs Node.js 20+ and build tools
2. Runs `npm install` (downloads ~200MB of dependencies)
3. Builds PrismGB with `npm run build:linux`
4. Creates ARM-native .deb package
5. Installs the package

**Time Required:**
- Pi Zero 2 W: 20-30 minutes
- Pi 4: 10-15 minutes
- Pi 5: 5-10 minutes

**Space Required:**
- ~2GB during build
- ~500MB after cleanup

## Method 2: Pre-built Binaries

If ARM builds are available in GitHub releases:

```bash
# On Raspberry Pi
curl -fsSL https://raw.githubusercontent.com/josstei/prismgb-app/main/raspberry-pi/setup.sh | bash
```

The setup script will:
1. Detect your architecture (ARM64/ARM32)
2. Download the appropriate pre-built package
3. Install PrismGB
4. Configure kiosk mode

## Method 3: Manual Build from Git

For development or if you want the latest code:

```bash
# On Raspberry Pi
git clone https://github.com/NicholasBM/prismgb-app.git
cd prismgb-app
npm install
npm run build:linux

# Install the built package
sudo dpkg -i release/PrismGB-*.deb

# Set up kiosk
cd raspberry-pi
./setup.sh
```

## Release Workflow

For maintainers creating releases:

### Option A: Source Package Only

```bash
# 1. Create source package
npm run package:rpi-source

# 2. Upload to GitHub release
# Upload: raspberry-pi/prismgb-source-{version}.tar.gz
```

Users download and build on their Pi.

### Option B: Pre-built ARM Binaries

If you have access to ARM hardware or CI:

```bash
# On ARM Linux system
npm install
npm run build:linux

# Upload to GitHub release
# Upload: release/PrismGB-{version}-arm64.deb
# Upload: release/PrismGB-{version}-armv7l.deb
```

### Option C: Both

Provide both source package and pre-built binaries:
- Source package for flexibility
- Pre-built binaries for convenience

## Comparison

| Method | Pros | Cons |
|--------|------|------|
| **Source Package** | ✅ No cross-compilation issues<br>✅ Always works<br>✅ Native performance | ⏱️ Slow first-time setup<br>💾 Requires build space |
| **Pre-built Binary** | ⚡ Fast installation<br>💾 Small download | ❌ Requires ARM build infrastructure<br>❌ Cross-compilation issues |
| **Git Clone** | ✅ Latest code<br>✅ Development-friendly | ⏱️ Slowest<br>💾 Largest download |

## Recommended Approach

**For end users:** Source package (Method 1)
- One-time 20-30 minute build
- Guaranteed to work
- No cross-compilation headaches

**For developers:** Git clone (Method 3)
- Easy to modify and test
- Can pull updates

**For releases:** Provide source package
- Upload `prismgb-source-{version}.tar.gz` to releases
- Users build on their Pi
- No need for ARM CI infrastructure

## Troubleshooting

### Build Fails with "Out of Memory"

```bash
# Increase swap space temporarily
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Try build again
./build-on-pi.sh

# Restore swap after build
sudo sed -i 's/CONF_SWAPSIZE=1024/CONF_SWAPSIZE=100/' /etc/dphys-swapfile
sudo dphys-swapfile setup
```

### Build is Too Slow

```bash
# Use fewer parallel jobs
npm config set jobs 1
npm install
npm run build:linux
```

### Not Enough Disk Space

```bash
# Check space
df -h

# Clean up if needed
sudo apt clean
rm -rf ~/.cache
rm -rf ~/.npm

# Need at least 2GB free for build
```