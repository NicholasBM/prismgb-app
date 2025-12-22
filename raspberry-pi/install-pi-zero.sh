#!/bin/bash

# PrismGB installer for Raspberry Pi Zero 2 W (Legacy)
# Pi 4 is recommended for better performance

set -e

VERSION="1.1.5"
GITHUB_REPO="NicholasBM/prismgb-pi"
PACKAGE_NAME="prismgb-pi-installer.tar.gz"

echo "========================================="
echo "🎮 PrismGB Pi Zero 2 W Installer (Legacy)"
echo "========================================="
echo ""
echo "⚠️  Note: Pi 4 is recommended for better performance"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run as regular user (not root)"
    echo "The script will use sudo when needed"
    exit 1
fi

echo "📡 Updating system..."
sudo apt update

echo "📦 Installing dependencies..."
sudo apt install -y wget curl

echo "⬇️  Downloading PrismGB installer package..."
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${PACKAGE_NAME}"

# Check available space and choose appropriate directory
TMP_AVAIL=$(df /tmp 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
if [ "$TMP_AVAIL" -lt 1000000 ]; then
    echo "⚠️  /tmp has limited space, using home directory..."
    WORK_DIR="$HOME/prismgb-install"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
fi

# Download with progress bar
wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "$PACKAGE_NAME"

# Check if download was successful
if [ ! -f "$PACKAGE_NAME" ]; then
    echo "❌ Download failed!"
    exit 1
fi

echo "📦 Installing PrismGB..."
tar -xzf "$PACKAGE_NAME"

# Check if extraction was successful
if [ ! -d prismgb-pi-installer ]; then
    echo "❌ Extraction failed!"
    exit 1
fi

sudo cp -r prismgb-pi-installer/* /

# Clean up
echo "🧹 Cleaning up..."
if [ -n "$WORK_DIR" ]; then
    cd "$HOME"
    rm -rf "$WORK_DIR"
else
    rm -f "$PACKAGE_NAME"
    rm -rf prismgb-pi-installer/
fi

echo "🔧 Setting up services..."
sudo systemctl daemon-reload
sudo systemctl enable prismgb-kiosk.service

# Install Electron if not present
if ! command -v electron &> /dev/null; then
    echo "📦 Installing Electron..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get update
    sudo apt-get install -y nodejs
    sudo npm install -g electron
fi

# Install cage if not present
if ! command -v cage &> /dev/null; then
    echo "📦 Installing cage..."
    sudo apt-get install -y cage
fi

# Configure auto-login
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Cleanup
rm -rf "$PACKAGE_NAME" prismgb-pi-installer/

echo ""
echo "✅ Installation complete!"
echo ""
echo "⚠️  Pi Zero 2 W limitations:"
echo "   - No auto-click/auto-fullscreen"
echo "   - Limited streaming performance"
echo "   - Basic kiosk mode only"
echo ""
echo "🔄 To start PrismGB kiosk mode:"
echo "   sudo systemctl start prismgb-kiosk"
echo ""
echo "🔄 Or reboot to start automatically:"
echo "   sudo reboot"
echo ""
echo "💡 Consider upgrading to Pi 4 for full features!"
echo ""

read -p "Start PrismGB kiosk mode now? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sudo systemctl start prismgb-kiosk
    echo "🎮 PrismGB is starting in kiosk mode!"
fi