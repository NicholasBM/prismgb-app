#!/bin/bash
#
# Fix missing build dependencies for PrismGB on Raspberry Pi
# Run this if the build failed with libudev.h missing
#

set -e

echo "========================================="
echo "Fixing PrismGB Build Dependencies"
echo "========================================="
echo ""

echo "Installing missing libudev-dev package..."
sudo apt update
sudo apt install -y libudev-dev

echo ""
echo "Retrying npm install in the source directory..."
cd ~/prismgb-source-1.1.0 2>/dev/null || {
    echo "Error: prismgb-source-1.1.0 directory not found"
    echo "Make sure you're in the right location or re-run the setup script"
    exit 1
}

echo "Cleaning previous build attempts..."
rm -rf node_modules package-lock.json

echo "Installing dependencies (this may take 10-15 minutes)..."
npm install

echo ""
echo "Building PrismGB..."
npm run build:linux

echo ""
echo "Installing the built package..."
DEB_FILE=$(ls release/*.deb | head -1)
if [ -f "$DEB_FILE" ]; then
    echo "Installing: $DEB_FILE"
    sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y
    echo ""
    echo "✅ PrismGB installed successfully!"
else
    echo "❌ Build failed - no .deb file found"
    exit 1
fi

echo ""
echo "Build complete! You can now continue with the kiosk setup."