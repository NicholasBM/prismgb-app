#!/bin/bash

# One-click PrismGB installer for Raspberry Pi Zero 2 W
# Downloads and installs the complete package

set -e

VERSION="1.1.5"
GITHUB_REPO="NicholasBM/prismgb-pi"
PACKAGE_NAME="prismgb-pi-installer.tar.gz"

echo "========================================="
echo "🎮 PrismGB Raspberry Pi Installer"
echo "========================================="
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

# Download with progress bar
wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "$PACKAGE_NAME"

echo "📦 Installing PrismGB..."
tar -xzf "$PACKAGE_NAME"
sudo cp -r prismgb-pi-installer/* /

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
echo "🔄 To start PrismGB kiosk mode:"
echo "   sudo systemctl start prismgb-kiosk"
echo ""
echo "🔄 Or reboot to start automatically:"
echo "   sudo reboot"
echo ""
echo "🛠️  Useful commands:"
echo "   sudo systemctl status prismgb-kiosk    # Check status"
echo "   sudo systemctl stop prismgb-kiosk      # Stop kiosk"
echo "   journalctl -u prismgb-kiosk -f         # View logs"
echo ""

read -p "Start PrismGB kiosk mode now? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sudo systemctl start prismgb-kiosk
    echo "🎮 PrismGB is starting in kiosk mode!"
fi