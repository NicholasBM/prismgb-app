#!/bin/bash
#
# Build PrismGB on Raspberry Pi from source package
#

set -e

echo "========================================="
echo "Building PrismGB on Raspberry Pi"
echo "========================================="
echo ""

# Check architecture
ARCH=$(uname -m)
echo "Architecture: $ARCH"

echo "Step 1: Checking system requirements..."
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
FREE_SPACE=$(df -m . | awk 'NR==2{printf "%.0f", $4}')

echo "Available RAM: ${TOTAL_MEM}MB"
echo "Free disk space: ${FREE_SPACE}MB"

if [ "$TOTAL_MEM" -lt 400 ]; then
    echo "⚠️  Warning: Low RAM detected. Build may fail."
    echo "Consider increasing swap or using a Pi with more RAM."
fi

if [ "$FREE_SPACE" -lt 2000 ]; then
    echo "❌ Error: Need at least 2GB free space for build"
    echo "Current free space: ${FREE_SPACE}MB"
    exit 1
fi

echo "Step 2: Installing build dependencies..."
sudo apt update
sudo apt install -y nodejs npm python3 build-essential libusb-1.0-0-dev libudev-dev

# Check Node.js version
echo "Step 3: Checking Node.js version..."
NODE_VERSION=$(node --version | cut -d'v' -f2)
REQUIRED_MAJOR=18

if [ "${NODE_VERSION%%.*}" -lt "$REQUIRED_MAJOR" ]; then
    echo "Node.js $NODE_VERSION is too old. Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"

# Configure npm for low-memory devices
echo "Step 4: Configuring npm for Raspberry Pi..."
npm config set jobs 1
npm config set fund false
npm config set audit false

# Install dependencies
echo "Step 5: Installing npm dependencies..."
echo "This may take 30-45 minutes on Pi Zero 2 W (single-threaded for stability)..."
echo "Progress will be shown to confirm it's working..."

# Clean any existing installation
rm -rf node_modules package-lock.json 2>/dev/null || true

# Install with verbose output and error handling
if ! npm install --verbose --no-optional; then
    echo ""
    echo "❌ npm install failed (likely out of memory)"
    echo ""
    echo "Troubleshooting options:"
    echo "1. Increase swap: sudo dphys-swapfile swapoff && sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile && sudo dphys-swapfile setup && sudo dphys-swapfile swapon"
    echo "2. Reboot and try again: sudo reboot"
    echo "3. Use a Pi with more RAM (Pi 4 2GB+ recommended)"
    echo ""
    exit 1
fi

# Build the application
echo "Step 6: Building PrismGB..."
echo "This may take 10-15 minutes..."
if ! npm run build:linux; then
    echo ""
    echo "❌ Build failed"
    echo "Check the output above for specific errors"
    exit 1
fi

# Install the built package
echo "Step 7: Installing PrismGB..."
DEB_FILE=$(ls release/*.deb 2>/dev/null | head -1)
if [ -f "$DEB_FILE" ]; then
    echo "Installing: $DEB_FILE"
    sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y
    echo ""
    echo "✅ PrismGB built and installed successfully!"
    
    # Verify installation
    if command -v prismgb >/dev/null 2>&1; then
        echo "✅ PrismGB command is available"
    else
        echo "⚠️  PrismGB command not found in PATH"
    fi
else
    echo "❌ Build failed - no .deb file found in release/"
    echo "Check the build output above for errors"
    exit 1
fi

echo ""
echo "🎉 Build complete! PrismGB is ready for kiosk setup."
echo ""
echo "Next steps:"
echo "1. cd raspberry-pi"
echo "2. chmod +x setup.sh"
echo "3. ./setup.sh"