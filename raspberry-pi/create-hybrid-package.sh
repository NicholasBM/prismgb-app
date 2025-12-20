#!/bin/bash
#
# Create hybrid source package - pre-install safe dependencies, exclude problematic ones
#

set -e

PACKAGE_NAME="prismgb-source"
VERSION="1.1.0"
PACKAGE_DIR="${PACKAGE_NAME}-${VERSION}"
ARCHIVE_NAME="${PACKAGE_DIR}-hybrid.tar.gz"

echo "========================================="
echo "Creating Hybrid PrismGB Source Package"
echo "========================================="

# Install dependencies on Mac first
echo "Step 1: Installing dependencies on Mac..."
cd ..
npm install
cd raspberry-pi

# Create package directory
rm -rf "$PACKAGE_DIR" "$ARCHIVE_NAME"
mkdir -p "$PACKAGE_DIR"

echo "Step 2: Copying source files..."
rsync -av \
  --exclude=dist \
  --exclude=release \
  --exclude=.git \
  --exclude=.vscode \
  --exclude=.DS_Store \
  --exclude="*.log" \
  --exclude=coverage \
  --exclude=.nyc_output \
  ../ "$PACKAGE_DIR/"

echo "Step 3: Optimizing node_modules for Pi..."
cd "$PACKAGE_DIR"

# Remove problematic build tools that need Pi-specific installation
PROBLEMATIC_PACKAGES=(
  "node_modules/vite"
  "node_modules/electron"
  "node_modules/electron-builder"
  "node_modules/@electron"
  "node_modules/esbuild*"
  "node_modules/@esbuild"
  "node_modules/rollup"
  "node_modules/@rollup"
  "node_modules/usb-detection"
  "node_modules/node-gyp"
  "node_modules/@electron/node-gyp"
)

echo "Removing problematic packages that need Pi-specific builds..."
for pkg in "${PROBLEMATIC_PACKAGES[@]}"; do
  rm -rf $pkg 2>/dev/null || true
done

# Create a list of packages to reinstall on Pi
echo "Creating reinstall list..."
cat > pi-reinstall-packages.txt << 'EOF'
vite
electron
electron-builder
usb-detection
@rollup/rollup-linux-arm64-gnu
EOF

cd ..

echo "Step 4: Creating optimized build script..."
cat > "$PACKAGE_DIR/build-on-pi.sh" << 'EOF'
#!/bin/bash
set -e

echo "========================================="
echo "Building PrismGB on Raspberry Pi (Hybrid)"
echo "========================================="

# System setup (same as before)
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
TOTAL_SWAP=$(free -m | awk 'NR==3{printf "%.0f", $2}')

echo "RAM: ${TOTAL_MEM}MB, Swap: ${TOTAL_SWAP}MB"

if [ "$TOTAL_SWAP" -lt 2000 ]; then
    echo "Creating swap..."
    sudo fallocate -l 2G /swapfile 2>/dev/null || true
    sudo chmod 600 /swapfile 2>/dev/null || true
    sudo mkswap /swapfile 2>/dev/null || true
    sudo swapon /swapfile 2>/dev/null || true
fi

echo "Installing build dependencies..."
sudo apt update
sudo apt install -y nodejs npm python3 build-essential libusb-1.0-0-dev libudev-dev

echo "Configuring npm..."
npm config set maxsockets 1
npm config set fund false
npm config set audit false

echo "Installing only missing build tools..."
if [ -f "pi-reinstall-packages.txt" ]; then
    echo "Installing Pi-specific packages..."
    while read -r package; do
        [ -n "$package" ] && npm install "$package" --no-save --verbose
    done < pi-reinstall-packages.txt
else
    echo "No reinstall list found, doing minimal install..."
    npm install vite electron electron-builder usb-detection --no-save --verbose
fi

echo "Building PrismGB..."
export ROLLUP_NO_NATIVE=1
npm run build:linux

echo "Installing .deb package..."
DEB_FILE=$(ls release/*.deb 2>/dev/null | head -1)
if [ -f "$DEB_FILE" ]; then
    sudo dpkg -i "$DEB_FILE"
    echo "✅ PrismGB installed successfully!"
else
    echo "❌ Build failed"
    exit 1
fi
EOF

chmod +x "$PACKAGE_DIR/build-on-pi.sh"

echo "Step 5: Creating archive..."
tar -czf "$ARCHIVE_NAME" "$PACKAGE_DIR"
rm -rf "$PACKAGE_DIR"

echo "✅ Hybrid package created: $ARCHIVE_NAME"
echo "📦 Size: $(du -h "$ARCHIVE_NAME" | cut -f1)"
echo ""
echo "This package includes:"
echo "- Pre-installed safe dependencies (~300MB)"
echo "- Excludes problematic build tools"
echo "- Pi will only install ~10 packages instead of 600+"