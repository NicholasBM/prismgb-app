#!/bin/bash

# Simple PrismGB Pi installer - actually works
# Installs everything needed for Pi Zero 2 W to display Chromatic on TV

set -e

echo "🎮 Installing PrismGB for Raspberry Pi Zero 2 W"
echo "This will set up your Pi to display Chromatic on TV"
echo ""

# Update system
echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# Install minimal desktop (needed for Electron)
echo "📺 Installing minimal desktop for TV output..."
sudo apt install -y --no-install-recommends \
    xserver-xorg \
    xinit \
    openbox \
    chromium-browser \
    nodejs \
    npm

# Install Electron globally
echo "⚡ Installing Electron..."
sudo npm install -g electron@28.3.3

# Download and install PrismGB
echo "⬇️  Installing PrismGB..."
cd /tmp
wget -O prismgb.tar.gz "https://github.com/NicholasBM/prismgb-app/releases/download/v1.1.5/prismgb-pi-installer.tar.gz"
tar -xzf prismgb.tar.gz
sudo cp -r prismgb-pi-installer/opt/prismgb /opt/
sudo chmod +x /opt/prismgb/prismgb

# Fix the launcher script
sudo tee /opt/prismgb/prismgb > /dev/null << 'EOF'
#!/bin/bash
cd /opt/prismgb
DISPLAY=:0 electron main/index.js "$@"
EOF
sudo chmod +x /opt/prismgb/prismgb

# Create symlink
sudo ln -sf /opt/prismgb/prismgb /usr/local/bin/prismgb

# Set up auto-login to console
sudo raspi-config nonint do_boot_behaviour B2

# Create startup script that launches X and PrismGB
sudo tee /home/pi/start-prismgb.sh > /dev/null << 'EOF'
#!/bin/bash
# Wait for system to be ready
sleep 5

# Start X server in background
sudo -u pi startx /opt/prismgb/prismgb -- :0 vt1 &

# Wait for X to start
sleep 3

# Set display
export DISPLAY=:0

# Launch PrismGB in fullscreen
/opt/prismgb/prismgb --kiosk --no-sandbox
EOF

sudo chmod +x /home/pi/start-prismgb.sh

# Set up auto-start
echo "/home/pi/start-prismgb.sh" | sudo tee -a /etc/rc.local > /dev/null

# USB permissions for Chromatic
sudo tee /etc/udev/rules.d/99-chromatic.rules > /dev/null << 'EOF'
SUBSYSTEM=="usb", ATTR{idVendor}=="374e", ATTR{idProduct}=="0101", MODE="0666", GROUP="plugdev"
EOF

sudo udevadm control --reload-rules

# Cleanup
rm -rf /tmp/prismgb*

echo ""
echo "✅ Installation complete!"
echo ""
echo "🔌 Connect your Pi to TV via HDMI"
echo "🔄 Reboot to start PrismGB automatically:"
echo "   sudo reboot"
echo ""
echo "🎮 Connect your Chromatic and it should appear on TV!"
echo ""
echo "To test manually: /opt/prismgb/prismgb"