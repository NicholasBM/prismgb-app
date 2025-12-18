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

echo "Step 2: Copying source files..."
# Copy essential files from parent directory, excluding build artifacts and dev files
rsync -av \
  --exclude=node_modules \
  --exclude=dist \
  --exclude=release \
  --exclude=.git \
  --exclude=.vscode \
  --exclude=.DS_Store \
  --exclude="*.log" \
  --exclude=coverage \
  --exclude=.nyc_output \
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

# Install build dependencies
echo "Step 1: Installing build dependencies..."
sudo apt update
sudo apt install -y nodejs npm python3 build-essential libusb-1.0-0-dev

# Check Node.js version
echo "Step 2: Checking Node.js version..."
NODE_VERSION=$(node --version | cut -d'v' -f2)
REQUIRED_MAJOR=18

if [ "${NODE_VERSION%%.*}" -lt "$REQUIRED_MAJOR" ]; then
    echo "Node.js $NODE_VERSION is too old. Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"

# Install dependencies
echo "Step 3: Installing npm dependencies..."
echo "This may take 10-20 minutes on Pi Zero 2 W..."
npm install

# Build the application
echo "Step 4: Building PrismGB..."
echo "This may take 5-10 minutes..."
npm run build:linux

# Install the built package
echo "Step 5: Installing PrismGB..."
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
- Try building with fewer parallel jobs: \`npm config set jobs 1\`
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