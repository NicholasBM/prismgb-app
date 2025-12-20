#!/bin/bash
#
# Build PrismGB directly on Raspberry Pi
# This avoids cross-compilation issues with native modules
#

set -e

echo "========================================="
echo "Building PrismGB on Raspberry Pi"
echo "========================================="
echo ""

# Check if we're on ARM
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "armv7l" ]]; then
    echo "Warning: Not running on ARM architecture ($ARCH)"
    echo "This script is designed for Raspberry Pi"
fi

echo "Step 1: Installing build dependencies..."
sudo apt update
sudo apt install -y git nodejs npm python3 build-essential libusb-1.0-0-dev libudev-dev

echo ""
echo "Step 2: Checking Node.js version..."
NODE_VERSION=$(node --version | cut -d'v' -f2)
REQUIRED_MAJOR=20

if [ "${NODE_VERSION%%.*}" -lt "$REQUIRED_MAJOR" ]; then
    echo "Node.js $NODE_VERSION is too old. Installing newer version..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

echo ""
echo "Step 3: Cloning PrismGB repository..."
if [ -d "prismgb-app" ]; then
    echo "Repository already exists, updating..."
    cd prismgb-app
    git pull
else
    git clone https://github.com/josstei/prismgb-app.git
    cd prismgb-app
fi

echo ""
echo "Step 4: Installing dependencies..."
echo "This may take 10-15 minutes on Pi Zero 2 W..."
npm install

echo ""
echo "Step 5: Building PrismGB..."
echo "This may take 5-10 minutes..."
npm run build:linux

echo ""
echo "Step 6: Installing the built package..."
DEB_FILE=$(ls release/*.deb | head -1)
if [ -f "$DEB_FILE" ]; then
    echo "Installing: $DEB_FILE"
    sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y
    echo ""
    echo "✅ PrismGB installed successfully!"
    echo ""
    echo "You can now run the kiosk setup:"
    echo "cd ../raspberry-pi && ./setup.sh"
else
    echo "❌ Build failed - no .deb file found"
    exit 1
fi

echo ""
echo "Build complete! PrismGB is ready to use."