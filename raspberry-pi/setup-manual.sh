#!/bin/bash
#
# PrismGB Raspberry Pi Manual Setup Script
# Use this when you've manually copied the source package to your Pi
#

set -e

PRISMGB_VERSION="1.1.0"
ARCH=$(uname -m)
USE_WAYLAND=true

echo "========================================="
echo "PrismGB Raspberry Pi Manual Setup"
echo "========================================="
echo ""

# Check if we're on a Pi
if [[ "$ARCH" != "aarch64" && "$ARCH" != "armv7l" ]]; then
    echo "⚠️  Warning: Not running on ARM architecture ($ARCH)"
    echo "This script is designed for Raspberry Pi"
    echo ""
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user (not root)"
    echo "The script will use sudo when needed"
    exit 1
fi

echo "Step 1: Checking for PrismGB source package..."
SOURCE_PACKAGE="prismgb-source-${PRISMGB_VERSION}.tar.gz"

if [ ! -f "$SOURCE_PACKAGE" ]; then
    echo "❌ Source package not found: $SOURCE_PACKAGE"
    echo ""
    echo "Please copy the source package to this directory first:"
    echo "  scp raspberry-pi/prismgb-source-${PRISMGB_VERSION}.tar.gz pi@raspberrypi.local:~"
    echo ""
    echo "Or create it on your development machine:"
    echo "  npm run package:rpi-source"
    exit 1
fi

echo "✅ Found source package: $SOURCE_PACKAGE"

echo ""
echo "Step 2: Checking if PrismGB is already installed..."
if command -v prismgb >/dev/null 2>&1; then
    echo "✅ PrismGB is already installed"
    PRISMGB_READY=true
else
    echo "PrismGB not found, will build from source"
    
    echo ""
    echo "⚠️  Building PrismGB will take 20-30 minutes on Pi Zero 2 W"
    echo "⚠️  Requires ~2GB free space and internet connection"
    echo ""
    read -p "Continue with build? [Y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    
    echo "Step 3: Extracting and building PrismGB..."
    tar -xzf "$SOURCE_PACKAGE"
    SOURCE_DIR="prismgb-source-${PRISMGB_VERSION}"
    
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "❌ Failed to extract source package"
        exit 1
    fi
    
    cd "$SOURCE_DIR"
    chmod +x build-on-pi.sh
    
    echo "Starting build (this will take a while)..."
    ./build-on-pi.sh
    
    cd ..
    echo "✅ PrismGB built and installed!"
    PRISMGB_READY=true
    
    # Clean up source files to save space
    echo "Cleaning up build files..."
    rm -rf "$SOURCE_DIR"
fi

echo ""
echo "Step 4: Setting up system dependencies..."
sudo apt update
sudo apt install -y libusb-1.0-0

echo ""
echo "Step 5: Setting up kiosk environment..."

# Ask user for Wayland or X11
read -p "Use Wayland compositor (recommended)? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    USE_WAYLAND=true
    echo "Installing Wayland (cage)..."
    sudo apt install -y cage
else
    USE_WAYLAND=false
    echo "Installing X11 minimal stack..."
    sudo apt install -y xserver-xorg xinit openbox unclutter
fi

echo ""
echo "Step 6: Creating systemd service..."

if [ "$USE_WAYLAND" = true ]; then
    sudo tee /etc/systemd/system/prismgb-kiosk.service > /dev/null <<'EOF'
[Unit]
Description=PrismGB Kiosk Mode (Wayland)
After=multi-user.target

[Service]
Type=simple
User=pi
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=PRISMGB_DISABLE_GPU=0
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/cage -s -- /usr/bin/prismgb --no-sandbox --kiosk
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
else
    sudo tee /etc/systemd/system/prismgb-kiosk.service > /dev/null <<'EOF'
[Unit]
Description=PrismGB Kiosk Mode (X11)
After=multi-user.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/pi/.Xauthority
Environment=PRISMGB_DISABLE_GPU=0
ExecStartPre=/bin/sleep 5
ExecStartPre=/usr/bin/startx /usr/bin/openbox-session -- :0 vt1 -nocursor
ExecStart=/usr/bin/prismgb --no-sandbox --kiosk
ExecStartPost=/usr/bin/unclutter -idle 0.1 -root &
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
fi

echo ""
echo "Step 7: Configuring auto-login..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

echo ""
echo "Step 8: Optimizing for performance..."

# GPU memory
if ! grep -q "gpu_mem=" /boot/firmware/config.txt 2>/dev/null; then
    echo "gpu_mem=128" | sudo tee -a /boot/firmware/config.txt
fi

# Disable unnecessary services
sudo systemctl disable bluetooth.service 2>/dev/null || true

# USB permissions for Chromatic
sudo tee /etc/udev/rules.d/99-chromatic.rules > /dev/null <<'EOF'
# Mod Retro Chromatic
SUBSYSTEM=="usb", ATTR{idVendor}=="374e", ATTR{idProduct}=="0101", MODE="0666", GROUP="plugdev"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

echo ""
echo "Step 9: Enabling kiosk service..."
sudo systemctl daemon-reload
sudo systemctl enable prismgb-kiosk.service

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "PrismGB will start automatically on next boot."
echo ""
echo "Useful commands:"
echo "  sudo systemctl status prismgb-kiosk.service  # Check status"
echo "  sudo systemctl stop prismgb-kiosk.service    # Stop kiosk"
echo "  sudo systemctl start prismgb-kiosk.service   # Start kiosk"
echo "  journalctl -u prismgb-kiosk.service -f       # View logs"
echo ""
read -p "Reboot now? [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    sudo reboot
fi