#!/bin/bash
#
# Smart Build PrismGB on Raspberry Pi - handles missing dependencies intelligently
#

set -e

echo "========================================="
echo "Building PrismGB on Raspberry Pi (Smart Mode)"
echo "========================================="
echo ""

# Check architecture
ARCH=$(uname -m)
echo "Architecture: $ARCH"

echo "Step 1: Checking system requirements..."
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
FREE_SPACE=$(df -m . | awk 'NR==2{printf "%.0f", $4}')
TOTAL_SWAP=$(free -m | awk 'NR==3{printf "%.0f", $2}')

echo "Available RAM: ${TOTAL_MEM}MB"
echo "Available swap: ${TOTAL_SWAP}MB"
echo "Free disk space: ${FREE_SPACE}MB"

if [ "$FREE_SPACE" -lt 3000 ]; then
    echo "❌ Error: Need at least 3GB free space for build"
    exit 1
fi

# Ensure adequate swap space
if [ "$TOTAL_SWAP" -lt 2000 ]; then
    echo "⚠️  Creating 2GB swap file..."
    if [ ! -f /swapfile ]; then
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
    fi
    sudo swapon /swapfile 2>/dev/null || true
    NEW_SWAP=$(free -m | awk 'NR==3{printf "%.0f", $2}')
    echo "✅ Swap: ${NEW_SWAP}MB"
fi

echo "Step 2: Installing build dependencies..."
sudo apt update
sudo apt install -y nodejs npm python3 build-essential libusb-1.0-0-dev libudev-dev

echo "Step 3: Configuring npm..."
npm config set maxsockets 1
npm config set fund false
npm config set audit false

echo "Step 4: Smart dependency management..."

if [ -d "node_modules" ] && [ "$(du -sm node_modules 2>/dev/null | cut -f1)" -gt 100 ]; then
    echo "✅ Pre-installed dependencies detected ($(du -sh node_modules | cut -f1))"
    
    # Install only specific missing packages
    echo "Installing missing ARM64 packages..."
    npm install exponential-backoff --no-save --verbose 2>/dev/null || echo "exponential-backoff already available"
    
    # Skip rebuild - go straight to build
    echo "✅ Skipping rebuild, using pre-installed dependencies"
else
    echo "❌ No dependencies found, doing minimal install..."
    npm install --no-optional --verbose
fi

echo "Step 5: Building PrismGB..."
export ROLLUP_NO_NATIVE=1

if ! npm run build:linux; then
    echo "❌ Build failed, trying with fresh dependencies..."
    rm -rf node_modules package-lock.json
    npm install --no-optional --verbose
    npm run build:linux
fi

echo "Step 6: Installing PrismGB..."
DEB_FILE=$(ls release/*.deb 2>/dev/null | head -1)
if [ -f "$DEB_FILE" ]; then
    sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y
    echo "✅ PrismGB installed successfully!"
else
    echo "❌ No .deb file found"
    exit 1
fi

echo "🎉 Build complete!"