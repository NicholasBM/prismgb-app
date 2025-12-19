#!/bin/bash

# Create a complete Pi installer package that works without compilation
# This bundles a pre-built x64 version that runs under emulation

set -e

VERSION="1.1.0"
PACKAGE_NAME="prismgb-pi-installer"

echo "🏗️  Creating Raspberry Pi installer package..."

# Create package structure
mkdir -p "${PACKAGE_NAME}/DEBIAN"
mkdir -p "${PACKAGE_NAME}/opt/prismgb"
mkdir -p "${PACKAGE_NAME}/usr/share/applications"
mkdir -p "${PACKAGE_NAME}/etc/systemd/system"
mkdir -p "${PACKAGE_NAME}/etc/udev/rules.d"

# Build the app first (x64 version)
echo "📦 Building PrismGB..."
npm run build

# Copy built app to package
echo "📋 Copying application files..."
cp -r dist/* "${PACKAGE_NAME}/opt/prismgb/"
cp -r node_modules "${PACKAGE_NAME}/opt/prismgb/"
cp package.json "${PACKAGE_NAME}/opt/prismgb/"

# Create launcher script
cat > "${PACKAGE_NAME}/opt/prismgb/prismgb" << 'EOF'
#!/bin/bash
cd /opt/prismgb
exec electron dist/main/index.js "$@"
EOF
chmod +x "${PACKAGE_NAME}/opt/prismgb/prismgb"

# Create symlink for global access
mkdir -p "${PACKAGE_NAME}/usr/local/bin"
ln -sf /opt/prismgb/prismgb "${PACKAGE_NAME}/usr/local/bin/prismgb"

# Create desktop entry
cat > "${PACKAGE_NAME}/usr/share/applications/prismgb.desktop" << EOF
[Desktop Entry]
Name=PrismGB
Comment=Game Boy emulator for Mod Retro Chromatic
Exec=/usr/local/bin/prismgb
Icon=prismgb
Terminal=false
Type=Application
Categories=Game;Emulator;
EOF

# Create systemd service for kiosk mode
cat > "${PACKAGE_NAME}/etc/systemd/system/prismgb-kiosk.service" << 'EOF'
[Unit]
Description=PrismGB Kiosk Mode
After=multi-user.target

[Service]
Type=simple
User=pi
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=DISPLAY=:0
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/cage -s -- /usr/local/bin/prismgb --no-sandbox --kiosk
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create udev rules for Chromatic
cat > "${PACKAGE_NAME}/etc/udev/rules.d/99-chromatic.rules" << 'EOF'
# Mod Retro Chromatic
SUBSYSTEM=="usb", ATTR{idVendor}=="374e", ATTR{idProduct}=="0101", MODE="0666", GROUP="plugdev"
EOF

# Create control file
cat > "${PACKAGE_NAME}/DEBIAN/control" << EOF
Package: prismgb
Version: ${VERSION}
Section: games
Priority: optional
Architecture: all
Depends: electron, cage, libc6, libusb-1.0-0
Maintainer: PrismGB Team
Description: Game Boy emulator for Raspberry Pi
 PrismGB is a desktop application for playing Game Boy games
 with the Mod Retro Chromatic device on Raspberry Pi.
EOF

# Create postinst script
cat > "${PACKAGE_NAME}/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Install Electron if not present
if ! command -v electron &> /dev/null; then
    echo "Installing Electron..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    apt-get update
    apt-get install -y nodejs
    npm install -g electron
fi

# Install cage if not present
if ! command -v cage &> /dev/null; then
    echo "Installing cage..."
    apt-get update
    apt-get install -y cage
fi

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

# Enable service but don't start it
systemctl daemon-reload
systemctl enable prismgb-kiosk.service

echo "PrismGB installed successfully!"
echo "To start kiosk mode: sudo systemctl start prismgb-kiosk"
echo "To enable auto-start: sudo systemctl enable prismgb-kiosk"
EOF

chmod +x "${PACKAGE_NAME}/DEBIAN/postinst"

# Create tar.gz package (works on macOS)
echo "📦 Creating installer package..."
TAR_FILE="${PACKAGE_NAME}.tar.gz"
tar -czf "$TAR_FILE" "${PACKAGE_NAME}"

echo "✅ Package created: $TAR_FILE"
echo ""
echo "🚀 To install on Raspberry Pi:"
echo "   scp $TAR_FILE pi@your-pi-ip:~/"
echo "   ssh pi@your-pi-ip"
echo "   tar -xzf $TAR_FILE"
echo "   sudo cp -r ${PACKAGE_NAME}/* /"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable prismgb-kiosk"
echo "   sudo systemctl start prismgb-kiosk"

# Cleanup
rm -rf "${PACKAGE_NAME}"

echo ""
echo "📋 Package contents:"
tar -tzf "$TAR_FILE" | head -20