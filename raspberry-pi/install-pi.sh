#!/bin/bash

# One-click PrismGB installer for Raspberry Pi Zero 2 W
# Simple, reliable, works every time

set -e

PRISMGB_VERSION="1.1.0"
GITHUB_REPO="NicholasBM/prismgb-app"

echo "========================================="
echo "🎮 PrismGB Raspberry Pi Installer"
echo "========================================="
echo ""

# Check if running on Pi
if [ ! -f /proc/device-tree/model ] || ! grep -q "Raspberry Pi" /proc/device-tree/model; then
    echo "⚠️  This script is designed for Raspberry Pi"
    read -p "Continue anyway? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run as regular user (not root)"
    echo "The script will use sudo when needed"
    exit 1
fi

echo "📡 Updating system..."
sudo apt update

echo "📦 Installing dependencies..."
sudo apt install -y wget curl libusb-1.0-0 libudev1

echo "⬇️  Downloading PrismGB ARM64..."
DEB_FILE="PrismGB-${PRISMGB_VERSION}-arm64.deb"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/v${PRISMGB_VERSION}/${DEB_FILE}"

# Download with progress bar
wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "$DEB_FILE"

echo "📦 Installing PrismGB..."
sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y

echo "🎯 Setting up kiosk mode..."

# Install minimal display server
sudo apt install -y cage

# Create systemd service
sudo tee /etc/systemd/system/prismgb-kiosk.service > /dev/null <<'EOF'
[Unit]
Description=PrismGB Kiosk Mode
After=multi-user.target

[Service]
Type=simple
User=pi
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStartPre=/bin/sleep 3
ExecStart=/usr/bin/cage -s -- /usr/bin/prismgb --no-sandbox --kiosk
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Configure auto-login
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# USB permissions for Chromatic
sudo tee /etc/udev/rules.d/99-chromatic.rules > /dev/null <<'EOF'
SUBSYSTEM=="usb", ATTR{idVendor}=="374e", ATTR{idProduct}=="0101", MODE="0666", GROUP="plugdev"
EOF

sudo udevadm control --reload-rules

# Enable services
sudo systemctl daemon-reload
sudo systemctl enable prismgb-kiosk.service

# Cleanup
rm -f "$DEB_FILE"

echo ""
echo "✅ Installation complete!"
echo ""
echo "🔄 Reboot to start PrismGB automatically:"
echo "   sudo reboot"
echo ""
echo "🛠️  Useful commands:"
echo "   sudo systemctl status prismgb-kiosk    # Check status"
echo "   sudo systemctl stop prismgb-kiosk      # Stop kiosk"
echo "   journalctl -u prismgb-kiosk -f         # View logs"
echo ""

read -p "Reboot now? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sudo reboot
fi