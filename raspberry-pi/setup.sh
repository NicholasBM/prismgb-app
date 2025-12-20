#!/bin/bash
#
# PrismGB Raspberry Pi Zero 2 W Kiosk Setup Script
# Automatically configures a Raspberry Pi to boot into PrismGB
#

set -e

PRISMGB_VERSION="1.1.0"
ARCH=$(uname -m)
USE_WAYLAND=true
FALLBACK_TO_X64=false

echo "========================================="
echo "PrismGB Raspberry Pi Kiosk Setup"
echo "========================================="
echo ""

# Detect architecture
if [ "$ARCH" = "aarch64" ]; then
    DEB_ARCH="arm64"
    echo "Detected: ARM64 (aarch64)"
elif [ "$ARCH" = "armv7l" ]; then
    DEB_ARCH="armv7l" 
    echo "Detected: ARM32 (armv7l)"
else
    echo "Unsupported architecture: $ARCH"
    echo "Falling back to x64 build (will use emulation)"
    DEB_ARCH="x64"
    FALLBACK_TO_X64=true
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user (not root)"
    echo "The script will use sudo when needed"
    exit 1
fi

echo ""
echo "Step 1: Updating system..."
sudo apt update
sudo apt upgrade -y

echo ""
echo "Step 2: Installing dependencies..."
sudo apt install -y libusb-1.0-0 wget curl

echo ""
echo "Step 3: Getting PrismGB..."

# Try pre-built ARM package first
DEB_FILE="PrismGB-${PRISMGB_VERSION}-${DEB_ARCH}.deb"
DOWNLOAD_URL="https://github.com/NicholasBM/prismgb-app/releases/download/v${PRISMGB_VERSION}/${DEB_FILE}"

echo "Checking for pre-built ARM package..."
if wget --spider "$DOWNLOAD_URL" 2>/dev/null; then
    echo "✅ Pre-built ARM package found! Downloading..."
    wget "$DOWNLOAD_URL"
    PRISMGB_READY=true
else
    # Try source package
    SOURCE_PACKAGE="prismgb-source-${PRISMGB_VERSION}.tar.gz"
    SOURCE_URL="https://github.com/NicholasBM/prismgb-app/releases/download/v${PRISMGB_VERSION}/${SOURCE_PACKAGE}"
    
    echo "No pre-built ARM package found."
    echo "Checking for source package..."
    
    if wget --spider "$SOURCE_URL" 2>/dev/null; then
        echo "✅ Source package found! This will build PrismGB on your Pi."
        echo "⚠️  Building will take 15-30 minutes and requires 2GB free space."
        echo ""
        read -p "Download and build from source? [Y/n]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "Setup cancelled."
            exit 0
        fi
        
        echo "Downloading source package..."
        wget "$SOURCE_URL"
        
        echo "Installing build dependencies..."
        sudo apt install -y git nodejs npm python3 build-essential libusb-1.0-0-dev libudev-dev
        
        echo "Extracting source package..."
        tar -xzf "$SOURCE_PACKAGE"
        SOURCE_DIR="prismgb-source-${PRISMGB_VERSION}"
        
        echo "Building PrismGB (this will take a while)..."
        cd "$SOURCE_DIR"
        chmod +x build-on-pi.sh
        ./build-on-pi.sh
        cd ..
        
        echo "✅ PrismGB built and installed!"
        PRISMGB_READY=true
        
        # Clean up source files to save space
        rm -rf "$SOURCE_DIR" "$SOURCE_PACKAGE"
    else
        echo ""
        echo "❌ Neither pre-built packages nor source package found!"
        echo ""
        echo "Manual options:"
        echo "1. Build from git: git clone https://github.com/NicholasBM/prismgb-app.git"
        echo "2. Wait for official ARM releases"
        echo ""
        read -p "Continue with kiosk setup anyway? [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled."
            exit 0
        fi
        
        echo "Continuing with kiosk setup (PrismGB not installed)..."
        SKIP_PRISMGB_INSTALL=true
    fi
fi

if [ "$SKIP_PRISMGB_INSTALL" != true ] && [ "$PRISMGB_READY" != true ]; then
    echo ""
    echo "Step 4: Installing PrismGB..."
    sudo dpkg -i "$DEB_FILE" || sudo apt-get install -f -y
elif [ "$SKIP_PRISMGB_INSTALL" = true ]; then
    echo ""
    echo "Step 4: Skipping PrismGB installation (not available)"
else
    echo ""
    echo "Step 4: PrismGB already installed from source build"
fi

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
ExecStartPost=/usr/bin/unclutter -idle 0.1 -root
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
