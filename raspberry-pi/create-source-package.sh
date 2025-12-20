#!/bin/bash
#
# Create a source package for Raspberry Pi deployment
# This packages the entire codebase for building on the target Pi
#

set -e

PACKAGE_NAME="prismgb-source"
VERSION=$(node -p "require('../package.json').version")
PACKAGE_DIR="${PACKAGE_NAME}-${VERSION}"
ARCHIVE_NAME="${PACKAGE_DIR}.tar.gz"

echo "========================================="
echo "Creating PrismGB Source Package"
echo "========================================="
echo ""

echo "Version: $VERSION"
echo "Package: $ARCHIVE_NAME"
echo ""

# Clean up any existing package
rm -rf "$PACKAGE_DIR" "$ARCHIVE_NAME"

echo "Step 1: Creating package directory..."
mkdir -p "$PACKAGE_DIR"

echo "Step 2: Installing dependencies on host machine..."
cd ..
if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
fi
cd raspberry-pi

echo "Step 3: Copying source files with dependencies..."
# Copy essential files from parent directory, including node_modules but excluding native binaries
rsync -av \
  --exclude=dist \
  --exclude=release \
  --exclude=.git \
  --exclude=.vscode \
  --exclude=.DS_Store \
  --exclude="*.log" \
  --exclude=coverage \
  --exclude=.nyc_output \
  --exclude="node_modules/**/*.node" \
  --exclude="node_modules/**/build/" \
  --exclude="node_modules/**/.deps/" \
  ../ "$PACKAGE_DIR/"

echo "Step 3: Creating build script for Pi..."
cat > "$PACKAGE_DIR/build-on-pi.sh" << 'EOF'
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
TOTAL_SWAP=$(free -m | awk 'NR==3{printf "%.0f", $2}')

echo "Available RAM: ${TOTAL_MEM}MB"
echo "Available swap: ${TOTAL_SWAP}MB"
echo "Free disk space: ${FREE_SPACE}MB"

if [ "$FREE_SPACE" -lt 3000 ]; then
    echo "❌ Error: Need at least 3GB free space for build (including swap file)"
    echo "Current free space: ${FREE_SPACE}MB"
    exit 1
fi

# Ensure adequate swap space for build
if [ "$TOTAL_SWAP" -lt 2000 ]; then
    echo "⚠️  Insufficient swap space detected (${TOTAL_SWAP}MB)"
    echo "Creating 2GB swap file for stable build..."
    
    # Create swap file if it doesn't exist
    if [ ! -f /swapfile ]; then
        sudo fallocate -l 2G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
    fi
    
    # Enable swap
    sudo swapon /swapfile 2>/dev/null || true
    
    # Verify swap is active
    NEW_SWAP=$(free -m | awk 'NR==3{printf "%.0f", $2}')
    echo "✅ Swap increased to ${NEW_SWAP}MB"
else
    echo "✅ Sufficient swap space available (${TOTAL_SWAP}MB)"
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
npm config set maxsockets 1
npm config set fund false
npm config set audit false

# Rebuild native dependencies for ARM64
echo "Step 5: Rebuilding native dependencies for ARM64..."
echo "This should only take 5-10 minutes (much faster than full install)..."

# Only rebuild native modules that need ARM64 compilation
if ! npm rebuild --verbose; then
    echo ""
    echo "❌ npm rebuild failed"
    echo ""
    echo "Trying full install as fallback..."
    rm -rf node_modules package-lock.json
    if ! npm install --verbose --no-optional; then
        echo "❌ Full install also failed"
        exit 1
    fi
fi

# Build the application
echo "Step 6: Building PrismGB..."
echo "This may take 10-15 minutes..."

# Set environment variable to use Rollup JS fallback on ARM (fixes missing ARM64 native binary)
export ROLLUP_NO_NATIVE=1

if ! npm run build:linux; then
    echo ""
    echo "❌ Build failed"
    echo ""
    echo "If you see Rollup ARM64 errors, try:"
    echo "  npm install @rollup/rollup-linux-arm64-gnu --save-optional"
    echo "  export ROLLUP_NO_NATIVE=1"
    echo "  npm run build:linux"
    echo ""
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
EOF

chmod +x "$PACKAGE_DIR/build-on-pi.sh"

echo "Step 4: Creating installation instructions..."
cat > "$PACKAGE_DIR/INSTALL.md" << EOF
# PrismGB Source Package Installation

This package contains the complete PrismGB source code for building on Raspberry Pi.

## Quick Install

\`\`\`bash
# Extract the package
tar -xzf prismgb-source-${VERSION}.tar.gz
cd prismgb-source-${VERSION}

# Build and install PrismGB
chmod +x build-on-pi.sh
./build-on-pi.sh

# Set up kiosk mode
cd raspberry-pi
chmod +x setup.sh
./setup.sh
\`\`\`

## Requirements

- Raspberry Pi with Raspberry Pi OS Lite (Bookworm)
- Internet connection for downloading dependencies
- At least 2GB free space for build process
- Patience (build takes 15-30 minutes on Pi Zero 2 W)

## What This Does

1. Installs Node.js and build tools
2. Downloads npm dependencies
3. Builds PrismGB for ARM architecture
4. Creates and installs .deb package
5. Sets up kiosk mode to boot into PrismGB

## Troubleshooting

If the build fails:
- Check you have enough free space: \`df -h\`
- Check memory usage: \`free -h\`
- Try building with fewer parallel jobs: \`npm config set maxsockets 1\`
- Reboot and try again if out of memory

## Performance Notes

- **Pi Zero 2 W**: Minimum, expect some lag
- **Pi 4 (2GB+)**: Good performance
- **Pi 5**: Best performance
EOF

echo "Step 5: Creating compressed archive..."
tar -czf "$ARCHIVE_NAME" "$PACKAGE_DIR"

echo "Step 6: Cleaning up..."
rm -rf "$PACKAGE_DIR"

echo ""
echo "✅ Source package created: $ARCHIVE_NAME"
echo "📦 Size: $(du -h "$ARCHIVE_NAME" | cut -f1)"
echo ""
echo "To use:"
echo "1. Copy $ARCHIVE_NAME to your Raspberry Pi"
echo "2. Extract: tar -xzf $ARCHIVE_NAME"
echo "3. Build: cd $PACKAGE_DIR && ./build-on-pi.sh"
echo ""